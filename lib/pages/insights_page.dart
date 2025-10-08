import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/widgets/section_title.dart';
import 'package:provider/provider.dart';
import '../models/period_model.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

enum SortOption {
  dateNewest,
  dateOldest,
  periodLengthShortest,
  periodLengthLongest,
  cycleLengthShortest,
  cycleLengthLongest,
}

class _InsightsPageState extends State<InsightsPage> {
  SortOption _currentSortOption = SortOption.dateNewest;

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.dateNewest:
        return 'Date (Newest First)';
      case SortOption.dateOldest:
        return 'Date (Oldest First)';
      case SortOption.periodLengthShortest:
        return 'Period Length (Shortest)';
      case SortOption.periodLengthLongest:
        return 'Period Length (Longest)';
      case SortOption.cycleLengthShortest:
        return 'Cycle Length (Shortest)';
      case SortOption.cycleLengthLongest:
        return 'Cycle Length (Longest)';
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
          int lengthA = a.endDate != null
              ? a.endDate!.difference(a.startDate).inDays + 1
              : 0;
          int lengthB = b.endDate != null
              ? b.endDate!.difference(b.startDate).inDays + 1
              : 0;
          return lengthA.compareTo(lengthB);
        });
        break;
      case SortOption.periodLengthLongest:
        sortedPeriods.sort((a, b) {
          int lengthA = a.endDate != null
              ? a.endDate!.difference(a.startDate).inDays + 1
              : 0;
          int lengthB = b.endDate != null
              ? b.endDate!.difference(b.startDate).inDays + 1
              : 0;
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
          int cycleLength = sortedPeriods[i].startDate
              .difference(sortedPeriods[i - 1].startDate)
              .inDays;
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

          return sortOption == SortOption.cycleLengthShortest
              ? cycleA.compareTo(cycleB)
              : cycleB.compareTo(cycleA);
        });
        break;
    }

    return sortedPeriods;
  }

  @override
  Widget build(BuildContext context) {
    final periodProvider = Provider.of<PeriodProvider>(context);
    List<Period> periods = context.watch<PeriodProvider>().periods;
    List<Period> sortedPeriods = _sortPeriods(periods, _currentSortOption);

    return SafeArea(
      child: periods.isEmpty
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No periods logged',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When you log periods, insights will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: () {
                      context.go(
                        '/log?isEditing=false&focusedDay=${Uri.encodeComponent(DateTime.now().toIso8601String())}',
                      );
                    },
                    child: Text('Log Period'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (periodProvider.getAverageCycleLength() != null &&
                    periodProvider.getAveragePeriodLength() != null)
                  SizedBox(
                    height: 130,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _statCard(
                            title: "Average Cycle Length",
                            value: periodProvider
                                .getAverageCycleLength()!
                                .toStringAsFixed(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: "Average Period Length",
                            value: periodProvider
                                .getAveragePeriodLength()!
                                .toStringAsFixed(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(
                            'Period History',
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          ),
                          if (periods.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                bottom: 8,
                              ),
                              child: Text(
                                'Sorted by: ${_getSortOptionText(_currentSortOption)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (periods.length > 1)
                      PopupMenuButton<SortOption>(
                        icon: Icon(
                          Icons.sort_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Sort periods',
                        onSelected: (SortOption value) {
                          setState(() {
                            _currentSortOption = value;
                          });
                        },
                        itemBuilder: (BuildContext context) =>
                            SortOption.values.map((option) {
                              IconData optionIcon;
                              switch (option) {
                                case SortOption.dateNewest:
                                  optionIcon = Icons.schedule_rounded;
                                  break;
                                case SortOption.dateOldest:
                                  optionIcon = Icons.history_rounded;
                                  break;
                                case SortOption.periodLengthShortest:
                                case SortOption.periodLengthLongest:
                                  optionIcon = Icons.straighten_rounded;
                                  break;
                                case SortOption.cycleLengthShortest:
                                case SortOption.cycleLengthLongest:
                                  optionIcon = Icons.refresh_rounded;
                                  break;
                              }

                              return PopupMenuItem<SortOption>(
                                value: option,
                                child: Row(
                                  children: [
                                    Icon(
                                      optionIcon,
                                      size: 18,
                                      color: _currentSortOption == option
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _getSortOptionText(option),
                                        style: TextStyle(
                                          fontWeight:
                                              _currentSortOption == option
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: _currentSortOption == option
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (_currentSortOption == option)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: sortedPeriods.map((period) {
                      int? periodLength = period.endDate != null
                          ? period.endDate!
                                    .difference(period.startDate)
                                    .inDays +
                                1
                          : null;

                      // Calculate cycle length for this period (if not the first one chronologically)
                      int? cycleLength;

                      // Always use date-sorted periods to find the chronologically previous period
                      List<Period> dateSortedPeriods = List.from(periods);
                      dateSortedPeriods.sort(
                        (a, b) => a.startDate.compareTo(b.startDate),
                      );

                      int dateIndex = dateSortedPeriods.indexOf(period);
                      if (dateIndex > 0) {
                        cycleLength = period.startDate
                            .difference(
                              dateSortedPeriods[dateIndex - 1].startDate,
                            )
                            .inDays;
                      }

                      return ListTile(
                        leading: Icon(
                          Icons.calendar_month_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          'Start: ${DateTimeHelper.displayDate(period.startDate)}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              period.endDate != null
                                  ? 'End: ${DateTimeHelper.displayDate(period.endDate!)}'
                                  : 'Ongoing',
                            ),
                            if (periodLength != null &&
                                (_currentSortOption ==
                                        SortOption.periodLengthShortest ||
                                    _currentSortOption ==
                                        SortOption.periodLengthLongest))
                              Text(
                                'Length: $periodLength day${periodLength == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            if ((_currentSortOption ==
                                    SortOption.cycleLengthShortest ||
                                _currentSortOption ==
                                    SortOption.cycleLengthLongest))
                              Text(
                                cycleLength != null
                                    ? 'Cycle: $cycleLength day${cycleLength == 1 ? '' : 's'}'
                                    : 'First Period',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: cycleLength != null
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.tertiary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          context.go(
                            '/log?isEditing=true&periodId=${period.id}&focusedDay=${Uri.encodeComponent(period.startDate.toIso8601String())}',
                          );
                          return;
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard({required String title, required String value}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
