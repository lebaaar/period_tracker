import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final periodProvider = Provider.of<PeriodProvider>(context);
    List<Period> periods = context.watch<PeriodProvider>().periods;

    final nextPeriod = periodProvider.getNextPeriodDate();
    final currentCycleDay = periodProvider.getCurrentCycleDay(DateTime.now());
    final avgCycleLength = periodProvider.getAverageCycleLength();
    final status = periodProvider.getStatusMessage();

    double progress = 0;
    if (avgCycleLength != null && avgCycleLength > 0) {
      progress = currentCycleDay / avgCycleLength;
      if (progress > 1) progress = 1;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section: Next period, current cycle day, status
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 20),
                  const SizedBox(height: 8),
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
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
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
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isPeriod = PeriodService.isInPeriod(day, periods);
                  final isWithinRange =
                      _rangeStart != null &&
                      _rangeEnd != null &&
                      !day.isBefore(_rangeStart!) &&
                      !day.isAfter(_rangeEnd!);
                  return Container(
                    decoration: BoxDecoration(
                      color: isPeriod
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2)
                          : isWithinRange
                          ? Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.3)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isPeriod
                              ? Theme.of(context).colorScheme.primary
                              : isWithinRange
                              ? Theme.of(context).colorScheme.secondary
                              : null,
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return Container(
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
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: periodProvider.getDataForDate(_selectedDay),
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
