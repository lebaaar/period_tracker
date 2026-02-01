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
import 'package:period_tracker/services/period_service.dart';
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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
    final periodProvider = Provider.of<PeriodProvider>(context);
    final List<Period> periods = context.watch<PeriodProvider>().periods;
    final Settings? settings = context.watch<SettingsProvider>().settings;
    final User? user = context.watch<UserProvider>().user;

    final List<DateTime> next3PeriodDates = periodProvider.getNext3PeriodDates(settings?.predictionMode == 'dynamic', user?.cycleLength);
    final DateTime? nextPeriodDate = next3PeriodDates.isNotEmpty ? next3PeriodDates[0] : null;

    final DateTime now = DateTime.now();
    final int currentCycleDay = periodProvider.getCurrentCycleDay(DateTime.utc(now.year, now.month, now.day));
    double? cycleLength;
    if (settings?.predictionMode == 'dynamic') {
      cycleLength = periodProvider.getAverageCycleLength(userCycleLength: user?.cycleLength); // provide userCycleLength if available
    } else {
      cycleLength = user?.cycleLength.toDouble();
    }

    final status = periodProvider.getStatusMessage(Theme.of(context).colorScheme.tertiary, nextPeriodDate);

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
      String userIsoCountryCode = userDbPhoneNumber?.split('|')[0] ?? kDefaultIsoCountryCode; // SI
      String userCountryCode = userDbPhoneNumber?.split('|')[1] ?? kDefaultCountryCode; // +386
      String userPhoneNumber = userDbPhoneNumber?.split('|')[2] ?? '';

      // Prefill phone number if it exists
      if (userPhoneNumber.isNotEmpty) {
        phoneController.text = userPhoneNumber;
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Order boyfriend'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IntlPhoneField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    if (user?.partnerMessageHeading?.isEmpty ?? true) const SizedBox(height: 12),
                    if (user?.partnerMessageHeading?.isNotEmpty ?? false) const SizedBox(height: 6),
                    if (user?.partnerMessageHeading?.isNotEmpty ?? false)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Title: ', style: DefaultTextStyle.of(context).style),
                            TextSpan(
                              text: user?.partnerMessageHeading ?? '',
                              style: DefaultTextStyle.of(context).style.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    if (user?.partnerMessageHeading?.isNotEmpty ?? false) const SizedBox(height: 6),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.tertiary),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (userPhoneNumber.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
                    return;
                  }

                  // Update user with new phone number
                  context.read<UserProvider>().updateUser(
                    name: user?.name,
                    cycleLength: user?.cycleLength ?? 28,
                    periodLength: user?.periodLength ?? 5,
                    partnerPhoneNumber: '$userIsoCountryCode|$userCountryCode|$userPhoneNumber',
                  );

                  // Build SMS message with optional heading
                  String smsBody = messageController.text;
                  if (user?.partnerMessageHeading?.isNotEmpty == true) {
                    smsBody = '${user?.partnerMessageHeading}\n\n$smsBody';
                  }

                  // Send SMS
                  final uri = Uri(scheme: 'sms', path: '$userCountryCode$userPhoneNumber', queryParameters: <String, String>{'body': smsBody});
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                    Navigator.of(context).pop();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open SMS app')));
                    }
                  }
                },
                child: const Text('Send'),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          );
        },
      );
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
                        Icon(Icons.calendar_month_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Next period:', style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              nextPeriodDate != null ? DateTimeHelper.displayDate(nextPeriodDate) : 'Not enough data',
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order boyfriend',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
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
                          Text('Current cycle day: $currentCycleDay', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                            minHeight: 8,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Text(status.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: status.color)),
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
                    weekdayStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                    weekendStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                  ),
                  calendarStyle: CalendarStyle(outsideDaysVisible: false),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) => _defaultBuilder(context, day, focusedDay, periods, next3PeriodDates, user),
                    todayBuilder: (context, day, focusedDay) => _todayBuilder(context, day, focusedDay, periods, next3PeriodDates, user),
                    selectedBuilder: (context, day, focusedDay) => _selectedBuilder(context, day, focusedDay, periods, next3PeriodDates, user),
                  ),
                ),
              ),
              Center(
                child: Padding(padding: const EdgeInsets.all(16.0), child: periodProvider.getDataForDate(_selectedDay, context)),
              ),
              SizedBox(height: 80), // to avoid FAB overlapping content
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final Period? selectedPeriod = PeriodService.getPeriodInDate(_selectedDay, periods);
          final bool isEditing = selectedPeriod != null;

          if (isEditing) {
            context.go('/log?isEditing=$isEditing&periodId=${selectedPeriod.id}&focusedDay=${Uri.encodeComponent(_selectedDay.toIso8601String())}');
            return;
          }
          context.go('/log?isEditing=false&focusedDay=${Uri.encodeComponent(_selectedDay.toIso8601String())}');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99.0)),
        child: PeriodService.getPeriodInDate(_selectedDay, periods) != null
            ? Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onPrimary)
            : Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _defaultBuilder(BuildContext context, DateTime day, DateTime focusedDay, periods, List<DateTime> next3PeriodDates, User? user) {
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
        : (isFirstDayOfMonth || isLastDayOfMonth) && period != null && period.startDate.month != period.endDate!.month;

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

    // next period dates (3) styling
    DateTime current = DateTimeHelper.stripTime(day);
    Color primaryColor = Theme.of(context).colorScheme.primary;

    for (int periodIndex = 0; periodIndex < next3PeriodDates.length; periodIndex++) {
      DateTime periodStart = DateTimeHelper.stripTime(next3PeriodDates[periodIndex]);
      DateTime periodEnd = DateTimeHelper.stripTime(next3PeriodDates[periodIndex].add(Duration(days: periodDuration)));

      if (DateTimeHelper.dayBetweenDates(current, periodStart, periodEnd)) {
        // day is inside one of the upcoming periods
        final isStartDay = DateTimeHelper.isSameDay(periodStart, day);
        final isEndDay = DateTimeHelper.isSameDay(periodEnd, day);

        decoration = BoxDecoration(
          border: Border(
            left: isStartDay ? BorderSide(color: primaryColor, width: 2.0) : BorderSide.none,
            right: isEndDay ? BorderSide(color: primaryColor, width: 2.0) : BorderSide.none,
            top: BorderSide(color: primaryColor, width: 2.0),
            bottom: BorderSide(color: primaryColor, width: 2.0),
          ),
          borderRadius: BorderRadius.horizontal(
            left: isStartDay ? const Radius.circular(99) : Radius.zero,
            right: isEndDay ? const Radius.circular(99) : Radius.zero,
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

  Widget _todayBuilder(BuildContext context, DateTime day, DateTime focusedDay, periods, List<DateTime> next3PeriodDates, User? user) {
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
      return _defaultBuilder(context, day, focusedDay, periods, next3PeriodDates, user);
    }

    // default styling that is returned if today is just a regular day, meaning it doesn't fall into any of the logged or upcoming periods
    BoxDecoration? decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
    );
    Color? textColor = Theme.of(context).colorScheme.onSurface;

    // Check if today is in any of the upcoming periods
    DateTime current = DateTimeHelper.stripTime(day);
    for (DateTime periodDate in next3PeriodDates) {
      DateTime periodStart = DateTimeHelper.stripTime(periodDate);
      DateTime periodEnd = DateTimeHelper.stripTime(periodDate.add(Duration(days: periodDuration)));

      if (DateTimeHelper.dayBetweenDates(current, periodStart, periodEnd)) {
        // today is inside one of the upcoming periods
        return _defaultBuilder(context, day, focusedDay, periods, next3PeriodDates, user);
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

  Widget _selectedBuilder(BuildContext context, DateTime day, DateTime focusedDay, periods, List<DateTime> next3PeriodDates, User? user) {
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
        : (isFirstDayOfMonth || isLastDayOfMonth) && period != null && period.startDate.month != period.endDate!.month;

    bool insideUpcomingPeriod = false;
    bool isNextPeriodStartDay = false;
    bool isNextPeriodEndDay = false;
    bool upComingSpanMultipleMonths = false;
    int periodDuration = kDefaultPeriodLength - 1;
    if (user != null) {
      periodDuration = user.periodLength - 1;
    }

    // Check if selected day is in any of the upcoming periods
    DateTime current = DateTimeHelper.stripTime(day);
    for (DateTime periodDate in next3PeriodDates) {
      DateTime periodStart = DateTimeHelper.stripTime(periodDate);
      DateTime periodEnd = DateTimeHelper.stripTime(periodDate.add(Duration(days: periodDuration)));

      if (DateTimeHelper.dayBetweenDates(current, periodStart, periodEnd)) {
        isNextPeriodStartDay = DateTimeHelper.isSameDay(periodStart, day);
        isNextPeriodEndDay = DateTimeHelper.isSameDay(periodEnd, day);
        insideUpcomingPeriod = true;

        // Check if this upcoming period spans multiple months
        upComingSpanMultipleMonths = (isFirstDayOfMonth || isLastDayOfMonth) && periodStart.month != periodEnd.month;

        break; // Only consider the first matching period
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
      decoration = BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle);
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
