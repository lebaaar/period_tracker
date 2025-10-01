import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
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
    final Settings? settings = context.watch<SettingsProvider>().settings;
    final User? user = context.watch<UserProvider>().user;

    final DateTime? nextPeriodDate = periodProvider.getNextPeriodDate(
      settings?.predictionMode == 'dynamic',
      user?.cycleLength,
    );
    DateTime tempDate = DateTime.now();
    final currentCycleDay = periodProvider.getCurrentCycleDay(
      DateTime.utc(tempDate.year, tempDate.month, tempDate.day),
    );
    final avgCycleLength = periodProvider.getAverageCycleLength(
      userCycleLength:
          user?.cycleLength, // provide userCycleLength if available
    );
    final status = periodProvider.getStatusMessage(
      Theme.of(context).colorScheme.tertiary,
      nextPeriodDate,
    );

    bool showProgressBar = avgCycleLength != null;
    double progress = 0;
    if (avgCycleLength != null && avgCycleLength > 0) {
      progress = currentCycleDay / avgCycleLength;
      if (progress > 1) progress = 1;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                              nextPeriodDate != null
                                  ? DateTimeHelper.displayDate(nextPeriodDate)
                                  : 'Not enough data',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (showProgressBar)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Text(
                      status.text,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: status.color),
                    ),
                  ],
                ),
              ),
              // Calendar section
              SizedBox(
                // height: 420, // probably don't need fixed height
                child: TableCalendar(
                  headerStyle: HeaderStyle(formatButtonVisible: false),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: kFirstCalendarDay,
                  lastDay: kLastCalendarDay,
                  focusedDay: _focusedDay,
                  availableGestures: AvailableGestures.horizontalSwipe,
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
                    defaultBuilder: (context, day, focusedDay) =>
                        _defaultBuilder(
                          context,
                          day,
                          focusedDay,
                          periods,
                          nextPeriodDate,
                          user,
                        ),
                    todayBuilder: (context, day, focusedDay) => _todayBuilder(
                      context,
                      day,
                      focusedDay,
                      periods,
                      nextPeriodDate,
                      user,
                    ),
                    selectedBuilder: (context, day, focusedDay) =>
                        _selectedBuilder(
                          context,
                          day,
                          focusedDay,
                          periods,
                          nextPeriodDate,
                          user,
                        ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: periodProvider.getDataForDate(_selectedDay, context),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Period? period = PeriodService.getPeriodInDate(_selectedDay, periods);
          bool isEditing = period != null;

          if (isEditing) {
            // Find the period being edited
            final Period? period = PeriodService.getPeriodInDate(
              _selectedDay,
              periods,
            );
            if (period == null) {
              // This should never happen, just in case
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Error: Could not find period to edit, please try again later',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
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
        child: PeriodService.getPeriodInDate(_selectedDay, periods) != null
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

  Widget _defaultBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    periods,
    DateTime? nextPeriodDate,
    User? user,
  ) {
    // distinguish 3 cases:
    // - selected date is inside logged period
    // - selected date is inside upcoming period
    // - default builder for all other dates

    Period? period = PeriodService.getPeriodInDate(day, periods);
    final isInPeriod = period != null;
    final isStartDay = PeriodService.isStartDay(day, periods);
    final isEndDay = PeriodService.isEndDay(day, periods);

    final bool isFirstDayOfMonth = DateTimeHelper.isFirstDayOfMonth(day);
    final bool isLastDayOfMonth = DateTimeHelper.isLastDayOfMonth(day);
    final bool spansMultipleMonths =
        isStartDay &&
            isEndDay // if this is true gradient is applied
        ? false // period lasts 1 single day - should never happen
        : (isFirstDayOfMonth || isLastDayOfMonth) &&
              period != null &&
              period.startDate.month != period.endDate!.month;

    BoxDecoration? decoration;
    Color? textColor;
    Gradient? gradient;
    if (spansMultipleMonths) {
      if (isInPeriod) {
        gradient = isFirstDayOfMonth
            ? kLoggedPeriodFirstMonthDayGradient
            : isLastDayOfMonth
            ? kLoggedPeriodLastMonthDayGradient
            : null;
      }
    }
    if (isInPeriod) {
      // day is inside logged period
      textColor = Theme.of(context).colorScheme.onSurface;
      decoration = BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        gradient: gradient,
        borderRadius: BorderRadius.horizontal(
          left: isStartDay ? const Radius.circular(99) : Radius.zero,
          right: isEndDay ? const Radius.circular(99) : Radius.zero,
        ),
      );
    }
    int periodDuration = kDefaultPeriodLength - 1;
    if (user != null) {
      periodDuration = user.periodLength - 1;
    }

    // next period date styling
    if (nextPeriodDate != null) {
      DateTime nextPeriodStart = DateTimeHelper.stripTime(nextPeriodDate);
      DateTime nextPeriodEnd = DateTimeHelper.stripTime(
        nextPeriodDate.add(Duration(days: periodDuration)),
      );
      DateTime current = DateTimeHelper.stripTime(day);
      Color primaryColor = Theme.of(context).colorScheme.primary;

      if (DateTimeHelper.dayBetweenDates(
        current,
        nextPeriodStart,
        nextPeriodEnd,
      )) {
        // day is inside upcoming period
        final isNextPeriodStartDay = DateTimeHelper.isSameDay(
          nextPeriodStart,
          day,
        );
        final isNextPeriodEndDay = DateTimeHelper.isSameDay(nextPeriodEnd, day);
        decoration = BoxDecoration(
          border: Border(
            left: isNextPeriodStartDay
                ? BorderSide(color: primaryColor, width: 2)
                : BorderSide.none,
            right: isNextPeriodEndDay
                ? BorderSide(color: primaryColor, width: 2)
                : BorderSide.none,
            top: BorderSide(color: primaryColor, width: 2),
            bottom: BorderSide(color: primaryColor, width: 2),
          ),
          borderRadius: BorderRadius.horizontal(
            left: isNextPeriodStartDay
                ? const Radius.circular(99)
                : Radius.zero,
            right: isNextPeriodEndDay ? const Radius.circular(99) : Radius.zero,
          ),
        );
      }
    }

    // default builder
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      decoration: decoration,
      child: Center(
        child: Text('${day.day}', style: TextStyle(color: textColor)),
      ),
    );
  }

  Widget _todayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    periods,
    DateTime? nextPeriodDate,
    User? user,
  ) {
    // distinguish 3 cases:
    // - selected date is inside logged period
    // - selected date is inside upcoming period
    // - default builder for all other dates
    final Period? period = PeriodService.getPeriodInDate(day, periods);
    final isInPeriod = period != null;
    int periodDuration = kDefaultPeriodLength - 1;
    if (user != null) {
      periodDuration = user.periodLength - 1;
    }

    if (isInPeriod) {
      // today is inside logged period
      return _defaultBuilder(
        context,
        day,
        focusedDay,
        periods,
        nextPeriodDate,
        user,
      );
    }

    // default styling that is returned if today is just a regular day, meaning it doesn't fall into any of the logged or upcoming periods
    BoxDecoration? decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.secondary,
        width: 2,
      ),
    );
    Color? textColor = Theme.of(context).colorScheme.onSurface;

    if (nextPeriodDate != null) {
      DateTime nextPeriodStart = DateTimeHelper.stripTime(nextPeriodDate);
      DateTime nextPeriodEnd = DateTimeHelper.stripTime(
        nextPeriodDate.add(Duration(days: periodDuration)),
      );
      DateTime current = DateTimeHelper.stripTime(day);

      if (DateTimeHelper.dayBetweenDates(
        current,
        nextPeriodStart,
        nextPeriodEnd,
      )) {
        // selected date is inside upcoming period
        return _defaultBuilder(
          context,
          day,
          focusedDay,
          periods,
          nextPeriodDate,
          user,
        );
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      decoration: decoration,
      child: Center(
        child: Text('${day.day}', style: TextStyle(color: textColor)),
      ),
    );
  }

  Widget _selectedBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    periods,
    DateTime? nextPeriodDate,
    User? user,
  ) {
    // distinguish 3 cases:
    // - selected date is inside logged period
    // - selected date is inside upcoming period
    // - default builder for all other dates
    final Period? period = PeriodService.getPeriodInDate(day, periods);
    final isInPeriod = period != null;
    final isStartDay = PeriodService.isStartDay(day, periods);
    final isEndDay = PeriodService.isEndDay(day, periods);

    final bool isFirstDayOfMonth = DateTimeHelper.isFirstDayOfMonth(day);
    final bool isLastDayOfMonth = DateTimeHelper.isLastDayOfMonth(day);
    final bool spansMultipleMonths =
        isStartDay &&
            isEndDay // if this is true gradient is applied
        ? false // period lasts 1 single day - should never happen
        : (isFirstDayOfMonth || isLastDayOfMonth) &&
              period != null &&
              period.startDate.month != period.endDate!.month;

    final upComingSpanMultipleMonths = isFirstDayOfMonth || isLastDayOfMonth;

    bool insideUpcomingPeriod = false;
    bool isNextPeriodStartDay = false;
    bool isNextPeriodEndDay = false;
    int periodDuration = kDefaultPeriodLength - 1;
    if (user != null) {
      periodDuration = user.periodLength - 1;
    }

    if (nextPeriodDate != null) {
      DateTime nextPeriodStart = DateTimeHelper.stripTime(nextPeriodDate);
      DateTime nextPeriodEnd = DateTimeHelper.stripTime(
        nextPeriodDate.add(Duration(days: periodDuration)),
      );
      DateTime current = DateTimeHelper.stripTime(day);

      if (DateTimeHelper.dayBetweenDates(
        current,
        nextPeriodStart,
        nextPeriodEnd,
      )) {
        isNextPeriodStartDay = DateTimeHelper.isSameDay(nextPeriodStart, day);
        isNextPeriodEndDay = DateTimeHelper.isSameDay(nextPeriodEnd, day);
        insideUpcomingPeriod = true;
      }
    }

    BoxDecoration? decoration;
    Color? textColor;
    Gradient? gradient;
    if (spansMultipleMonths) {
      if (isInPeriod) {
        gradient = isFirstDayOfMonth
            ? kLoggedSelectedPeriodFirstMonthDayGradient
            : isLastDayOfMonth
            ? kLoggedSelectedPeriodLastMonthDayGradient
            : null;
      }
    } else if (upComingSpanMultipleMonths) {
      if (insideUpcomingPeriod) {
        gradient = isFirstDayOfMonth
            ? kUpcomingSelectedPeriodFirstMonthDayGradient
            : isLastDayOfMonth
            ? kUpcomingSelectedPeriodLastMonthDayGradient
            : null;
      }
    }
    if (isInPeriod) {
      // selected date is inside logged period
      decoration = BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        gradient: gradient,
        borderRadius: BorderRadius.horizontal(
          left: isStartDay ? const Radius.circular(99) : Radius.zero,
          right: isEndDay ? const Radius.circular(99) : Radius.zero,
        ),
      );
      textColor = Theme.of(context).colorScheme.surface;
    } else if (insideUpcomingPeriod) {
      // selected day is inside upcoming period
      decoration = BoxDecoration(
        gradient: gradient,
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.horizontal(
          left: isNextPeriodStartDay ? const Radius.circular(99) : Radius.zero,
          right: isNextPeriodEndDay ? const Radius.circular(99) : Radius.zero,
        ),
      );
      textColor = Theme.of(context).colorScheme.surface;
    } else {
      // default selector builder
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
        child: Text('${day.day}', style: TextStyle(color: textColor)),
      ),
    );
  }
}
