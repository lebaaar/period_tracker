import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _selectedDay;
  DateTime _focusedDay = DateTime.now();
  bool _showOrderBoyfriend = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _selectedDay = _focusedDay;
  }

  Future<void> _loadPreferences() async {
    final versionDetails = await getDisplayVersionDetails();
    final animalGenerator = await getAnimalGeneratorUnlocked();
    if (!mounted) return;
    setState(() {
      _showOrderBoyfriend = versionDetails && animalGenerator;
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodProvider = context.watch<PeriodProvider>();
    final List<Period> periods = periodProvider.periods;
    final Settings? settings = context.watch<SettingsProvider>().settings;
    final User? user = context.watch<UserProvider>().user;

    final List<DateTime> next3PeriodDates = periodProvider.getNext3PeriodDates(
      settings?.predictionMode == 'dynamic',
      user?.cycleLength,
    );
    final DateTime? nextPeriodDate = next3PeriodDates.isNotEmpty
        ? next3PeriodDates[0]
        : null;
    final int periodDuration = (user?.periodLength ?? kDefaultPeriodLength) - 1;
    final _CalendarDayLookup calendarDayLookup = _buildCalendarDayLookup(
      periods,
      next3PeriodDates,
      periodDuration,
    );

    final DateTime now = DateTime.now();
    final int currentCycleDay = periodProvider.getCurrentCycleDay(
      DateTime.utc(now.year, now.month, now.day),
    );
    double? cycleLength;
    if (settings?.predictionMode == 'dynamic') {
      cycleLength = periodProvider.getAverageCycleLength(
        userCycleLength: user?.cycleLength,
      ); // provide userCycleLength if available
    } else {
      cycleLength = user?.cycleLength.toDouble();
    }

    final status = periodProvider.getStatusMessage(
      Theme.of(context).colorScheme.tertiary,
      nextPeriodDate,
    );
    final Period? selectedPeriod =
        calendarDayLookup.loggedDays[_dayKey(_selectedDay)]?.period;

    final bool showProgressBar = cycleLength != null;
    double progress = 0;
    if (cycleLength != null && cycleLength > 0) {
      progress = currentCycleDay / cycleLength;
      if (progress > 1) progress = 1;
    }

    void orderBoyfriend() {
      final TextEditingController messageController = TextEditingController();
      final TextEditingController phoneController = TextEditingController();
      String? userDbPhoneNumber = user?.partnerPhoneNumber;
      String userIsoCountryCode =
          userDbPhoneNumber?.split('|')[0] ?? kDefaultIsoCountryCode; // SI
      String userCountryCode =
          userDbPhoneNumber?.split('|')[1] ?? kDefaultCountryCode; // +386
      String userPhoneNumber = userDbPhoneNumber?.split('|')[2] ?? '';

      // Prefill phone number if it exists
      if (userPhoneNumber.isNotEmpty) {
        phoneController.text = userPhoneNumber;
      }

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Order boyfriend'),
            content: SizedBox(
              width: MediaQuery.of(dialogContext).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IntlPhoneField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      initialCountryCode: userIsoCountryCode,
                      onCountryChanged: (value) {
                        userIsoCountryCode = value.code;
                        userCountryCode = value.dialCode;
                      },
                      onChanged: (phone) {
                        userIsoCountryCode = phone.countryISOCode;
                        userCountryCode = phone.countryCode;
                        userPhoneNumber = phone.number;
                      },
                    ),
                    if (user?.partnerMessageHeading?.isEmpty ?? true)
                      const SizedBox(height: 12),
                    if (user?.partnerMessageHeading?.isNotEmpty ?? false)
                      const SizedBox(height: 6),
                    if (user?.partnerMessageHeading?.isNotEmpty ?? false)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Title: ',
                              style: DefaultTextStyle.of(dialogContext).style,
                            ),
                            TextSpan(
                              text: user?.partnerMessageHeading ?? '',
                              style: DefaultTextStyle.of(
                                dialogContext,
                              ).style.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    if (user?.partnerMessageHeading?.isNotEmpty ?? false)
                      const SizedBox(height: 6),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.tertiary,
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (userPhoneNumber.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a phone number'),
                      ),
                    );
                    return;
                  }

                  // Update user with new phone number
                  context.read<UserProvider>().updateUser(
                    name: user?.name,
                    cycleLength: user?.cycleLength ?? 28,
                    periodLength: user?.periodLength ?? 5,
                    partnerPhoneNumber:
                        '$userIsoCountryCode|$userCountryCode|$userPhoneNumber',
                  );

                  // Build SMS message with optional heading
                  String smsBody = messageController.text;
                  if (user?.partnerMessageHeading?.isNotEmpty == true) {
                    smsBody = '${user?.partnerMessageHeading}\n\n$smsBody';
                  }

                  // Send SMS
                  final encodedBody = Uri.encodeComponent(smsBody);
                  final uri = Uri.parse(
                    'sms:$userCountryCode$userPhoneNumber?body=$encodedBody',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  } else {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Could not open SMS app')),
                    );
                  }
                },
                child: const Text('Send'),
              ),
            ],
            backgroundColor: Theme.of(
              dialogContext,
            ).colorScheme.primaryContainer,
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          key: const PageStorageKey('home-scroll-view'),
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
                        Spacer(),
                        if (_showOrderBoyfriend)
                          InkWell(
                            onTap: orderBoyfriend,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite_rounded,
                                    size: 28,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order boyfriend',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ),
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
              RepaintBoundary(
                child: SizedBox(
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
                            calendarDayLookup,
                          ),
                      todayBuilder: (context, day, focusedDay) => _todayBuilder(
                        context,
                        day,
                        focusedDay,
                        calendarDayLookup,
                      ),
                      selectedBuilder: (context, day, focusedDay) =>
                          _selectedBuilder(
                            context,
                            day,
                            focusedDay,
                            calendarDayLookup,
                          ),
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
              SizedBox(height: 80), // to avoid FAB overlapping content
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bool isEditing = selectedPeriod != null;

          if (isEditing) {
            context.go(
              '/log?isEditing=$isEditing&periodId=${selectedPeriod.id}&focusedDay=${Uri.encodeComponent(_selectedDay.toIso8601String())}',
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
        child: selectedPeriod != null
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

  _CalendarDayLookup _buildCalendarDayLookup(
    List<Period> periods,
    List<DateTime> next3PeriodDates,
    int periodDuration,
  ) {
    final Map<int, _LoggedPeriodDay> loggedDays = {};
    final Map<int, _UpcomingPeriodDay> upcomingDays = {};

    for (final Period period in periods) {
      final DateTime? endDate = period.endDate;
      if (endDate == null) continue;

      DateTime current = DateTimeHelper.stripTime(period.startDate);
      final DateTime end = DateTimeHelper.stripTime(endDate);
      while (!current.isAfter(end)) {
        final bool isStartDay = DateTimeHelper.isSameDay(
          current,
          period.startDate,
        );
        final bool isEndDay = DateTimeHelper.isSameDay(current, endDate);
        loggedDays[_dayKey(current)] = _LoggedPeriodDay(
          period: period,
          isStartDay: isStartDay,
          isEndDay: isEndDay,
          spansMultipleMonths:
              !(isStartDay && isEndDay) &&
              (DateTimeHelper.isFirstDayOfMonth(current) ||
                  DateTimeHelper.isLastDayOfMonth(current)) &&
              period.startDate.month != endDate.month,
        );
        current = current.add(const Duration(days: 1));
      }
    }

    for (final DateTime periodDate in next3PeriodDates) {
      final DateTime periodStart = DateTimeHelper.stripTime(periodDate);
      final DateTime periodEnd = DateTimeHelper.stripTime(
        periodDate.add(Duration(days: periodDuration)),
      );
      DateTime current = periodStart;
      while (!current.isAfter(periodEnd)) {
        final bool isStartDay = DateTimeHelper.isSameDay(periodStart, current);
        final bool isEndDay = DateTimeHelper.isSameDay(periodEnd, current);
        upcomingDays[_dayKey(current)] = _UpcomingPeriodDay(
          isStartDay: isStartDay,
          isEndDay: isEndDay,
          spansMultipleMonths:
              (DateTimeHelper.isFirstDayOfMonth(current) ||
                  DateTimeHelper.isLastDayOfMonth(current)) &&
              periodStart.month != periodEnd.month,
        );
        current = current.add(const Duration(days: 1));
      }
    }

    return _CalendarDayLookup(
      loggedDays: loggedDays,
      upcomingDays: upcomingDays,
    );
  }

  static int _dayKey(DateTime date) {
    final DateTime strippedDate = DateTimeHelper.stripTime(date);
    return strippedDate.year * 10000 +
        strippedDate.month * 100 +
        strippedDate.day;
  }

  Widget _defaultBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    _CalendarDayLookup calendarDayLookup,
  ) {
    // distinguish 3 cases:
    // - selected date is inside logged period
    // - selected date is inside upcoming period
    // - default builder for all other dates

    final _LoggedPeriodDay? loggedPeriodDay =
        calendarDayLookup.loggedDays[_dayKey(day)];
    final _UpcomingPeriodDay? upcomingPeriodDay =
        calendarDayLookup.upcomingDays[_dayKey(day)];
    final isInPeriod = loggedPeriodDay != null;
    final isStartDay = loggedPeriodDay?.isStartDay ?? false;
    final isEndDay = loggedPeriodDay?.isEndDay ?? false;

    final bool isFirstDayOfMonth = DateTimeHelper.isFirstDayOfMonth(day);
    final bool isLastDayOfMonth = DateTimeHelper.isLastDayOfMonth(day);
    final bool spansMultipleMonths =
        loggedPeriodDay?.spansMultipleMonths ?? false;

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

    // next period dates (3) styling
    Color primaryColor = Theme.of(context).colorScheme.primary;

    if (upcomingPeriodDay != null) {
      decoration = BoxDecoration(
        border: Border(
          left: upcomingPeriodDay.isStartDay
              ? BorderSide(color: primaryColor, width: 2.0)
              : BorderSide.none,
          right: upcomingPeriodDay.isEndDay
              ? BorderSide(color: primaryColor, width: 2.0)
              : BorderSide.none,
          top: BorderSide(color: primaryColor, width: 2.0),
          bottom: BorderSide(color: primaryColor, width: 2.0),
        ),
        borderRadius: BorderRadius.horizontal(
          left: upcomingPeriodDay.isStartDay
              ? const Radius.circular(99)
              : Radius.zero,
          right: upcomingPeriodDay.isEndDay
              ? const Radius.circular(99)
              : Radius.zero,
        ),
      );
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
    _CalendarDayLookup calendarDayLookup,
  ) {
    // distinguish 3 cases:
    // - selected date is inside logged period
    // - selected date is inside upcoming period
    // - default builder for all other dates
    final bool isInPeriod = calendarDayLookup.loggedDays.containsKey(
      _dayKey(day),
    );
    final bool isInUpcomingPeriod = calendarDayLookup.upcomingDays.containsKey(
      _dayKey(day),
    );

    if (isInPeriod || isInUpcomingPeriod) {
      // today is inside logged period
      return _defaultBuilder(context, day, focusedDay, calendarDayLookup);
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
    _CalendarDayLookup calendarDayLookup,
  ) {
    // distinguish 3 cases:
    // - selected date is inside logged period
    // - selected date is inside upcoming period
    // - default builder for all other dates
    final _LoggedPeriodDay? loggedPeriodDay =
        calendarDayLookup.loggedDays[_dayKey(day)];
    final _UpcomingPeriodDay? upcomingPeriodDay =
        calendarDayLookup.upcomingDays[_dayKey(day)];
    final isInPeriod = loggedPeriodDay != null;
    final isStartDay = loggedPeriodDay?.isStartDay ?? false;
    final isEndDay = loggedPeriodDay?.isEndDay ?? false;

    final bool isFirstDayOfMonth = DateTimeHelper.isFirstDayOfMonth(day);
    final bool isLastDayOfMonth = DateTimeHelper.isLastDayOfMonth(day);
    final bool spansMultipleMonths =
        loggedPeriodDay?.spansMultipleMonths ?? false;
    final bool insideUpcomingPeriod = upcomingPeriodDay != null;
    final bool isNextPeriodStartDay = upcomingPeriodDay?.isStartDay ?? false;
    final bool isNextPeriodEndDay = upcomingPeriodDay?.isEndDay ?? false;
    final bool upComingSpanMultipleMonths =
        upcomingPeriodDay?.spansMultipleMonths ?? false;

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

class _CalendarDayLookup {
  final Map<int, _LoggedPeriodDay> loggedDays;
  final Map<int, _UpcomingPeriodDay> upcomingDays;

  const _CalendarDayLookup({
    required this.loggedDays,
    required this.upcomingDays,
  });
}

class _LoggedPeriodDay {
  final Period period;
  final bool isStartDay;
  final bool isEndDay;
  final bool spansMultipleMonths;

  const _LoggedPeriodDay({
    required this.period,
    required this.isStartDay,
    required this.isEndDay,
    required this.spansMultipleMonths,
  });
}

class _UpcomingPeriodDay {
  final bool isStartDay;
  final bool isEndDay;
  final bool spansMultipleMonths;

  const _UpcomingPeriodDay({
    required this.isStartDay,
    required this.isEndDay,
    required this.spansMultipleMonths,
  });
}
