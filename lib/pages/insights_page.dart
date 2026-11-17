import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/grouped_section.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/primary_button.dart';
import 'package:period_tracker/widgets/segmented_control.dart';
import 'package:provider/provider.dart';

import '../models/period_model.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

enum SortOption { dateNewest, dateOldest, periodLengthShortest, periodLengthLongest, cycleLengthShortest, cycleLengthLongest }

class _InsightsPageState extends State<InsightsPage> {
  SortOption _currentSortOption = SortOption.dateNewest;
  bool _recentOnly = true; // averages over the last 6 periods vs. all time

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.dateNewest:
        return 'Newest first';
      case SortOption.dateOldest:
        return 'Oldest first';
      case SortOption.periodLengthShortest:
        return 'Shortest period';
      case SortOption.periodLengthLongest:
        return 'Longest period';
      case SortOption.cycleLengthShortest:
        return 'Shortest cycle';
      case SortOption.cycleLengthLongest:
        return 'Longest cycle';
    }
  }

  List<Period> _sortPeriods(List<Period> periods, SortOption sortOption) {
    List<Period> sortedPeriods = List.from(periods);

    switch (sortOption) {
      case SortOption.dateNewest:
        sortedPeriods.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case SortOption.dateOldest:
        sortedPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case SortOption.periodLengthShortest:
        sortedPeriods.sort((a, b) {
          int lengthA = a.endDate != null ? a.endDate!.difference(a.startDate).inDays + 1 : 0;
          int lengthB = b.endDate != null ? b.endDate!.difference(b.startDate).inDays + 1 : 0;
          return lengthA.compareTo(lengthB);
        });
        break;
      case SortOption.periodLengthLongest:
        sortedPeriods.sort((a, b) {
          int lengthA = a.endDate != null ? a.endDate!.difference(a.startDate).inDays + 1 : 0;
          int lengthB = b.endDate != null ? b.endDate!.difference(b.startDate).inDays + 1 : 0;
          return lengthB.compareTo(lengthA);
        });
        break;
      case SortOption.cycleLengthShortest:
      case SortOption.cycleLengthLongest:
        // Sort by cycle length (gap between periods)
        // First, sort by date to ensure proper order for cycle calculations
        sortedPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));

        Map<Period, int> cycleLengths = {};

        for (int i = 1; i < sortedPeriods.length; i++) {
          int cycleLength = sortedPeriods[i].startDate.difference(sortedPeriods[i - 1].startDate).inDays;
          cycleLengths[sortedPeriods[i]] = cycleLength;
        }

        // Sort based on cycle lengths
        sortedPeriods.sort((a, b) {
          int cycleA = cycleLengths[a] ?? 0;
          int cycleB = cycleLengths[b] ?? 0;

          // Periods without cycle length (first period) go to the end
          if (cycleA == 0 && cycleB != 0) return 1;
          if (cycleB == 0 && cycleA != 0) return -1;
          if (cycleA == 0 && cycleB == 0) return 0;

          return sortOption == SortOption.cycleLengthShortest ? cycleA.compareTo(cycleB) : cycleB.compareTo(cycleA);
        });
        break;
    }

    return sortedPeriods;
  }

  String _rangeLabel(Period p) {
    if (p.endDate == null) return '${DateFormat('d MMM yyyy').format(p.startDate)} – ongoing';
    final bool sameYear = p.startDate.year == p.endDate!.year;
    final String start = DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy').format(p.startDate);
    return '$start – ${DateFormat('d MMM yyyy').format(p.endDate!)}';
  }

  void _logPeriod() => context.go('/log?isEditing=false&focusedDay=${Uri.encodeComponent(DateTime.now().toIso8601String())}');

  Future<void> _pickSort() async {
    final SortOption? picked = await showSelectSheet<SortOption>(
      context: context,
      title: 'Sort history',
      selected: _currentSortOption,
      options: [for (final SortOption o in SortOption.values) SelectOption(value: o, label: _getSortOptionText(o), icon: _sortIcon(o))],
    );
    if (picked != null && mounted) setState(() => _currentSortOption = picked);
  }

  IconData _sortIcon(SortOption option) => switch (option) {
    SortOption.dateNewest => Icons.arrow_downward_rounded,
    SortOption.dateOldest => Icons.arrow_upward_rounded,
    SortOption.periodLengthShortest || SortOption.periodLengthLongest => Icons.straighten_rounded,
    SortOption.cycleLengthShortest || SortOption.cycleLengthLongest => Icons.autorenew_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final PeriodProvider periodProvider = context.watch<PeriodProvider>();
    final List<Period> periods = periodProvider.periods;
    final List<Period> sortedPeriods = _sortPeriods(periods, _currentSortOption);
    final c = context.colors;

    // always use date-sorted periods to find the chronologically previous one
    final List<Period> byDate = List.from(periods)..sort((a, b) => a.startDate.compareTo(b.startDate));

    final double? avgCycle = periodProvider.getAverageCycleLength(useRecent6: _recentOnly);
    final double? avgPeriod = periodProvider.getAveragePeriodLength(useRecent6: _recentOnly);

    return LargeTitleScaffold(
      title: 'Insights',
      showBack: false,
      // The empty state has its own button.
      titleTrailing: periods.isEmpty ? null : PrimaryButton(label: 'Log period', icon: Icons.add_rounded, expand: false, compact: true, onPressed: _logPeriod),
      slivers: [
        if (periods.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              // Optical centring: the title and tab bar make a true centre look low.
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 190),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
                    child: Icon(Icons.show_chart_rounded, size: 32, color: c.labelSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text('Nothing to show yet', style: context.text.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Log a few periods and your averages and history will show up here.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(color: c.labelSecondary),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Log period', icon: Icons.add_rounded, expand: false, height: 46, onPressed: _logPeriod),
                ],
              ),
            ),
          )
        else ...[
          if (avgCycle != null && avgPeriod != null) ...[
            if (periods.length > 6)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SegmentedControl<bool>(
                    options: const [
                      SegmentOption(value: true, label: 'Last 6'),
                      SegmentOption(value: false, label: 'All time'),
                    ],
                    selected: _recentOnly,
                    onChanged: (v) => setState(() => _recentOnly = v),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(label: 'Average cycle', value: avgCycle.toStringAsFixed(1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(label: 'Average period', value: avgPeriod.toStringAsFixed(1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: GroupedSection(
              header: 'History',
              headerTrailing: periods.length > 1
                  ? Semantics(
                      label: 'Sort periods',
                      child: Pressable(
                        onTap: _pickSort,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getSortOptionText(_currentSortOption), style: context.text.bodyMedium?.copyWith(color: c.labelSecondary)),
                              const SizedBox(width: 4),
                              Icon(Icons.unfold_more_rounded, color: c.labelSecondary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,
              children: [
                for (final Period period in sortedPeriods)
                  Builder(
                    builder: (context) {
                      final int? length = period.endDate != null ? period.endDate!.difference(period.startDate).inDays + 1 : null;
                      final int idx = byDate.indexOf(period);
                      final int? cycle = idx > 0 ? period.startDate.difference(byDate[idx - 1].startDate).inDays : null;
                      final List<String> parts = [
                        ?(length != null ? '$length ${length == 1 ? 'day' : 'days'}' : null),
                        cycle != null ? '$cycle-day cycle' : 'First logged',
                      ];
                      return GroupedRow(
                        title: _rangeLabel(period),
                        subtitle: parts.join('  ·  '),
                        onTap: () =>
                            context.go('/log?isEditing=true&periodId=${period.id}&focusedDay=${Uri.encodeComponent(period.startDate.toIso8601String())}'),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodyMedium?.copyWith(color: c.labelSecondary)),
          const SizedBox(height: 10),
          Text(value, style: context.text.displayMedium),
          Text('days', style: context.text.bodyMedium?.copyWith(color: c.labelSecondary)),
        ],
      ),
    );
  }
}
