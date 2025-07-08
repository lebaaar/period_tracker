import 'package:flutter/material.dart';
import 'package:period_tracker/models/period.dart';
import 'package:period_tracker/period_provider.dart';
import 'package:period_tracker/constants.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final periodProvider = Provider.of<PeriodProvider>(context);
    List<Period> periods = context.watch<PeriodProvider>().periods;

    final nextPeriod = periodProvider.getNextPeriodDate();
    final currentCycleDay = periodProvider.getCurrentCycleDay(
      _selectedDay ?? _focusedDay,
    );
    final avgCycleLength = periodProvider.getAverageCycleLength();
    final status = periodProvider.getStatusMessage();

    double progress = 0;
    if (avgCycleLength != null && avgCycleLength > 0) {
      progress = currentCycleDay / avgCycleLength;
      if (progress > 1) progress = 1;
    }

    // Get period ranges from provider
    final List<DateTimeRange> periodRanges = periods
        .where((p) => p.endDate != null)
        .map((p) => DateTimeRange(start: p.startDate, end: p.endDate!))
        .toList();

    bool isInPeriod(DateTime day) {
      return periodRanges.any(
        (range) =>
            day.isAfter(range.start.subtract(const Duration(days: 1))) &&
            day.isBefore(range.end.add(const Duration(days: 1))),
      );
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
                        Icons.calendar_month,
                        size: 32,
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
                                ? _formatDate(nextPeriod)
                                : 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Current cycle: day $currentCycleDay',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status,
                    style: TextStyle(
                      color: status.contains('late')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Calendar section
            TableCalendar(
              firstDay: kFirstCalendarDay,
              lastDay: kLastCalendarDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              weekNumbersVisible: false,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isPeriod = isInPeriod(day);
                  return Container(
                    decoration: BoxDecoration(
                      color: isPeriod
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isPeriod
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Data section: Display data for selected day
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: periodProvider.getDataForDate(
                  _selectedDay ?? _focusedDay,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
