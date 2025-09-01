import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _selectedDay;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Test notification
    NotificationService().scheduleNotification(
      0,
      'Period soon',
      'Your period is expected in n days.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodProvider = Provider.of<PeriodProvider>(context);
    List<Period> periods = context.watch<PeriodProvider>().periods;

    final nextPeriod = periodProvider.getNextPeriodDate();
    final currentCycleDay = periodProvider.getCurrentCycleDay(DateTime.now());
    final avgCycleLength = periodProvider.getAverageCycleLength();
    final status = periodProvider.getStatusMessage(
      Theme.of(context).colorScheme.tertiary,
    );

    double progress = 0;
    if (avgCycleLength != null && avgCycleLength > 0) {
      progress = currentCycleDay / avgCycleLength;
      if (progress > 1) progress = 1;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next period:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            nextPeriod != null
                                ? DateTimeHelper.displayDate(nextPeriod)
                                : 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Current cycle day: $currentCycleDay',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: status.color,
                    ), // TODO, method to get color based on status, no hardcoded colors
                  ),
                ],
              ),
            ),
            // Calendar section
            TableCalendar(
              headerStyle: HeaderStyle(formatButtonVisible: false),
              startingDayOfWeek: StartingDayOfWeek.monday,
              firstDay: kFirstCalendarDay,
              lastDay: kLastCalendarDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarFormat: CalendarFormat.month,
              rangeSelectionMode: RangeSelectionMode.toggledOff,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _rangeStart = null;
                  }
                });
              },
              daysOfWeekHeight: kTableCalendarDaysOfTheWeekHeight,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                weekendStyle: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              calendarStyle: CalendarStyle(outsideDaysVisible: false),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isInPeriod = PeriodService.isInPeriod(day, periods);
                  final isStartDay = PeriodService.isStartDay(day, periods);
                  final isEndDay = PeriodService.isEndDay(day, periods);

                  BoxDecoration? decoration;
                  Color? textColor;
                  if (isInPeriod) {
                    decoration = BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.horizontal(
                        left: isStartDay
                            ? const Radius.circular(99)
                            : Radius.zero,
                        right: isEndDay
                            ? const Radius.circular(99)
                            : Radius.zero,
                      ),
                    );
                    textColor = Theme.of(context).colorScheme.onSurface;
                  }

                  return Container(
                    margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    decoration: decoration,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final isInPeriod = PeriodService.isInPeriod(day, periods);
                  if (!isInPeriod) {}
                  return Container(
                    margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final isInPeriod = PeriodService.isInPeriod(day, periods);
                  final isStartDay = PeriodService.isStartDay(day, periods);
                  final isEndDay = PeriodService.isEndDay(day, periods);

                  BoxDecoration? decoration;
                  Color? textColor;
                  if (isInPeriod) {
                    decoration = BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.horizontal(
                        left: isStartDay
                            ? const Radius.circular(99)
                            : Radius.zero,
                        right: isEndDay
                            ? const Radius.circular(99)
                            : Radius.zero,
                      ),
                    );
                    textColor = Theme.of(context).colorScheme.surface;
                  } else {
                    decoration = BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    );
                    textColor = Theme.of(context).colorScheme.onPrimary;
                  }

                  return Container(
                    margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    decoration: decoration,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: periodProvider.getDataForDate(_selectedDay, context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          bool isEditing = PeriodService.isInPeriod(_selectedDay, periods);

          if (isEditing) {
            // Find the period being edited
            final Period period = periods.firstWhere(
              (p) =>
                  !p.startDate.isAfter(_selectedDay) &&
                  p.endDate != null &&
                  !p.endDate!.isBefore(_selectedDay),
            );
            context.go(
              '/log?isEditing=$isEditing&periodId=${period.id}&focusedDay=${Uri.encodeComponent(_selectedDay.toIso8601String())}',
            );
            return;
          }
          context.go(
            '/log?isEditing=false&focusedDay=${Uri.encodeComponent(_selectedDay.toIso8601String())}',
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99.0),
        ),
        child: PeriodService.isInPeriod(_selectedDay, periods)
            ? Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
      ),
    );
  }
}
