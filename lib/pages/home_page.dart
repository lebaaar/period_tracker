import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/cycle_ring.dart';
import 'package:period_tracker/widgets/grouped_section.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/order_boyfriend_fields.dart';
import 'package:period_tracker/widgets/period_calendar.dart';
import 'package:period_tracker/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDay = clock.now();

  DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  void _openLog(Period? period) {
    final DateTime now = clock.now();
    // Future start dates are rejected, so open on today.
    final DateTime day = period == null && _utc(_selectedDay).isAfter(_utc(now)) ? now : _selectedDay;
    final String focused = Uri.encodeComponent(day.toIso8601String());
    if (period != null) {
      context.go('/log?isEditing=true&periodId=${period.id}&focusedDay=$focused');
    } else {
      context.go('/log?isEditing=false&focusedDay=$focused');
    }
  }

  @override
  Widget build(BuildContext context) {
    final PeriodProvider periodProvider = context.watch<PeriodProvider>();
    final List<Period> periods = periodProvider.periods;
    final Settings? settings = context.watch<SettingsProvider>().settings;
    final User? user = context.watch<UserProvider>().user;
    final bool showOrderBoyfriend = context.watch<UnlocksProvider>().orderBoyfriend;

    final bool dynamicMode = settings?.predictionMode == 'dynamic';
    final List<DateTime> predicted = periodProvider.getNext3PeriodDates(dynamicMode, user?.cycleLength);
    final DateTime? nextPeriodDate = predicted.isNotEmpty ? predicted.first : null;
    final int periodLength = user?.periodLength ?? kDefaultPeriodLength;
    final DateTime today = _utc(clock.now());
    final _CycleStatus status = _CycleStatus.compute(
      context: context,
      periods: periods,
      nextPeriodDate: nextPeriodDate,
      today: today,
      cycleDay: periodProvider.getCurrentCycleDay(today),
      cycleLength: dynamicMode ? periodProvider.getAverageCycleLength(userCycleLength: user?.cycleLength) : user?.cycleLength.toDouble(),
    );

    final bool firstRun = periods.isEmpty && periodProvider.isLoaded;

    return LargeTitleScaffold(
      // First run: the prompt is the page title.
      title: firstRun ? 'Log your last period' : 'Today',
      subtitle: firstRun ? _FirstRunIntro(onLog: () => _openLog(null)) : (periods.isEmpty ? null : _StatusText(status: status)),
      titleTrailing: periods.isEmpty ? null : _StatusRing(status: status),
      showBack: false,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: PeriodCalendar(
              initialFocusedDay: _selectedDay,
              firstDay: kFirstCalendarDay,
              lastDay: kLastCalendarDay,
              periods: periods,
              predictedStarts: predicted,
              predictedLength: periodLength,
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
          ),
        ),
        // The first-run intro already has a Log button.
        if (!firstRun)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SelectedDayCard(
                day: _selectedDay,
                today: today,
                periods: periods,
                predicted: predicted,
                predictedLength: periodLength,
                cycleDay: periodProvider.getCurrentCycleDay(_utc(_selectedDay)),
                onAction: _openLog,
              ),
            ),
          ),
        if (showOrderBoyfriend)
          SliverToBoxAdapter(
            child: GroupedSection(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                GroupedRow(
                  icon: Icons.favorite_rounded,
                  iconColor: context.colors.accent,
                  title: 'Order boyfriend',
                  subtitle: 'Send a message asking for backup',
                  onTap: () => _orderBoyfriend(user),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _orderBoyfriend(User? user) async {
    final String? stored = user?.partnerPhoneNumber;
    final List<String> parts = stored?.split('|') ?? const [];
    String isoCode = parts.isNotEmpty ? parts[0] : kDefaultIsoCountryCode;
    String dialCode = parts.length > 1 ? parts[1] : kDefaultCountryCode;
    String number = parts.length > 2 ? parts[2] : '';
    String message = '';
    final String heading = user?.partnerMessageHeading ?? '';

    await showAppSheet<void>(
      context: context,
      title: 'Order boyfriend',
      message: heading.isNotEmpty ? heading : null,
      actionLabel: 'Send',
      closeOnAction: false,
      onAction: () async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final NavigatorState navigator = Navigator.of(context);
        if (number.isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
          return;
        }

        context.read<UserProvider>().updateUser(
          name: user?.name,
          cycleLength: user?.cycleLength ?? 28,
          periodLength: user?.periodLength ?? 5,
          partnerPhoneNumber: '$isoCode|$dialCode|$number',
        );

        String body = message;
        if (heading.isNotEmpty) body = '$heading\n\n$body';
        final Uri uri = Uri.parse('sms:$dialCode$number?body=${Uri.encodeComponent(body)}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          navigator.pop();
        } else {
          messenger.showSnackBar(const SnackBar(content: Text('Could not open SMS app')));
        }
      },
      builder: (_) => OrderBoyfriendFields(
        initialIsoCode: isoCode,
        initialNumber: number,
        onPhoneChanged: (iso, dial, value) {
          isoCode = iso;
          dialCode = dial;
          number = value;
        },
        onMessageChanged: (value) => message = value,
      ),
    );
  }
}

/// Header text and ring values for the current cycle state.
class _CycleStatus {
  final String headline; // "Period in 14 days"
  final String? detail; // "Next period Tue, 1 Dec"
  final int cycleDay;
  final double progress;
  final bool late;

  const _CycleStatus({required this.headline, required this.detail, required this.cycleDay, required this.progress, required this.late});

  static _CycleStatus compute({
    required BuildContext context,
    required List<Period> periods,
    required DateTime? nextPeriodDate,
    required DateTime today,
    required int cycleDay,
    required double? cycleLength,
  }) {
    final Period? current = PeriodService.getPeriodInDate(today, periods);
    final int? daysUntil = nextPeriodDate == null ? null : DateTimeHelper.stripTime(nextPeriodDate).difference(today).inDays;

    String headline;
    bool late = false;
    if (current != null) {
      final int dayOfPeriod = today.difference(DateTimeHelper.stripTime(current.startDate)).inDays + 1;
      headline = 'Day $dayOfPeriod of your period';
    } else if (daysUntil == null) {
      headline = 'Not enough data yet';
    } else if (daysUntil < 0) {
      headline = '${-daysUntil} ${-daysUntil == 1 ? 'day' : 'days'} late';
      late = true;
    } else if (daysUntil == 0) {
      headline = 'Period due today';
    } else if (daysUntil == 1) {
      headline = 'Period tomorrow';
    } else {
      headline = 'Period in $daysUntil days';
    }

    return _CycleStatus(
      headline: headline,
      detail: nextPeriodDate == null ? null : 'Next period ${DateFormat('EEE, d MMM').format(nextPeriodDate)}',
      cycleDay: cycleDay,
      progress: (cycleLength != null && cycleLength > 0) ? (cycleDay / cycleLength).clamp(0.0, 1.0) : 0,
      late: late,
    );
  }
}

class _StatusText extends StatelessWidget {
  final _CycleStatus status;
  const _StatusText({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status.headline, style: context.text.titleMedium?.copyWith(color: status.late ? c.late : c.label)),
        if (status.detail != null) Text(status.detail!, style: context.text.bodyMedium?.copyWith(color: c.labelSecondary)),
      ],
    );
  }
}

/// Cycle progress ring beside the title; shows the cycle day.
class _StatusRing extends StatelessWidget {
  final _CycleStatus status;
  const _StatusRing({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (status.cycleDay <= 0) return const SizedBox.shrink();
    return Semantics(
      label: 'Cycle day ${status.cycleDay}',
      child: CycleRing(
        progress: status.progress,
        progressColor: status.late ? c.late : c.accent,
        size: 68,
        stroke: 7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${status.cycleDay}', style: context.text.titleLarge?.copyWith(height: 1.0)),
            Text('day', style: context.text.bodySmall?.copyWith(height: 1.2, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Intro and button under the first-run title.
class _FirstRunIntro extends StatelessWidget {
  final VoidCallback onLog;
  const _FirstRunIntro({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add when it started and predictions will appear here.', style: context.text.bodyLarge?.copyWith(color: context.colors.labelSecondary)),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Log period', icon: Icons.add_rounded, expand: false, height: 46, onPressed: onLog),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final List<Period> periods;
  final List<DateTime> predicted;
  final int predictedLength;
  final int cycleDay;
  final void Function(Period? period) onAction;

  const _SelectedDayCard({
    required this.day,
    required this.today,
    required this.periods,
    required this.predicted,
    required this.predictedLength,
    required this.cycleDay,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final DateTime d = DateTimeHelper.stripTime(day);
    final bool isFuture = d.isAfter(today);
    final Period? period = PeriodService.getPeriodInDate(d, periods);

    bool inPredicted = false;
    for (final DateTime start in predicted) {
      final DateTime s = DateTimeHelper.stripTime(start);
      if (DateTimeHelper.dayBetweenDates(d, s, s.add(Duration(days: predictedLength - 1)))) {
        inPredicted = true;
      }
    }

    final int diff = d.difference(today).inDays;
    final String fact;
    if (period != null) {
      final int dayOfPeriod = d.difference(DateTimeHelper.stripTime(period.startDate)).inDays + 1;
      final int length = DateTimeHelper.stripTime(period.endDate!).difference(DateTimeHelper.stripTime(period.startDate)).inDays + 1;
      fact = 'Period · day $dayOfPeriod of $length';
    } else if (inPredicted) {
      fact = 'Predicted period · in $diff ${diff == 1 ? 'day' : 'days'}';
    } else if (isFuture) {
      fact = 'In $diff ${diff == 1 ? 'day' : 'days'}';
    } else {
      fact = cycleDay > 0 ? 'Cycle day $cycleDay' : 'Before your first logged period';
    }
    final String notes = period?.notes?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEE, d MMM').format(day), style: context.text.titleMedium),
                      const SizedBox(height: 1),
                      Text(
                        fact,
                        style: context.text.bodyMedium?.copyWith(color: c.labelSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: period != null ? 'Edit period' : 'Log period',
                  child: PrimaryButton(
                    label: period != null ? 'Edit' : 'Log',
                    icon: period != null ? Icons.edit_rounded : Icons.add_rounded,
                    expand: false,
                    compact: true,
                    onPressed: () => onAction(period),
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 18, color: c.labelTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(notes, style: context.text.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}
