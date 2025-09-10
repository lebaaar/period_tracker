import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/widgets/section_title.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class LogPeriodPage extends StatefulWidget {
  final bool isEditing;
  final Period? period;
  final DateTime? focusedDay;
  const LogPeriodPage({
    super.key,
    required this.isEditing,
    this.period,
    this.focusedDay,
  });

  @override
  State<LogPeriodPage> createState() => _LogPeriodPageState();
}

class _LogPeriodPageState extends State<LogPeriodPage> {
  late final TextEditingController _notesController;
  DateTime today = DateTime.now();
  DateTime? rangeStart;
  DateTime? rangeEnd;
  DateTime focusedDay = DateTime.now();

  bool _initialLoad = true;
  DateTime? _initialRangeStart;
  DateTime? _initialRangeEnd;
  String? _initialNotes;

  bool get isEditing => widget.isEditing;
  Period? get period => widget.period;

  void _onSave(BuildContext context) {
    // Check if range is selected
    if (rangeStart == null || rangeEnd == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a period range'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check for overlapping periods
    final periods = context.read<PeriodProvider>().periods;
    final hasOverlap = PeriodService.isOverlappingPeriod(
      rangeStart!,
      periods,
      newEndDate: rangeEnd,
      excludeId: isEditing && period != null ? period!.id : null,
    );
    if (hasOverlap) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected period overlaps with an existing one.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    DateTime now = DateTime.now();
    DateTime checkDate = DateTime.utc(now.year, now.month, now.day);

    // Check if period is in the future
    final isInFuture = rangeStart!.isAfter(checkDate);
    if (isInFuture) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The start date cannot be in the future.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check minimum days between periods
    final sortedPeriods = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (final p in sortedPeriods) {
      if (isEditing && period != null && p.id == period!.id) continue;
      final gapBefore = rangeStart!.difference(p.endDate ?? p.startDate).inDays;
      final gapAfter = (p.startDate.difference(rangeEnd!).inDays);
      if (gapBefore >= 0 && gapBefore < kMinDaysBetweenPeriods ||
          gapAfter >= 0 && gapAfter < kMinDaysBetweenPeriods) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'There must be at least $kMinDaysBetweenPeriods days between periods.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Check if editing an existing period
    if (isEditing && period != null) {
      final updatedPeriod = Period(
        id: period!.id,
        startDate: DateTime.utc(
          rangeStart!.year,
          rangeStart!.month,
          rangeStart!.day,
        ),
        endDate: DateTime.utc(rangeEnd!.year, rangeEnd!.month, rangeEnd!.day),
        notes: _notesController.text,
      );
      context.read<PeriodProvider>().updatePeriod(updatedPeriod);
      Navigator.of(context).pop();
      return;
    }

    Period newPeriod = Period(
      startDate: rangeStart!,
      endDate: rangeEnd!,
      notes: _notesController.text,
    );
    context.read<PeriodProvider>().insertPeriod(newPeriod);
    context.read<PeriodProvider>().fetchPeriods();
    // TODO - notifications
    Navigator.of(context).pop();
  }

  bool isPageDirty() {
    if (isEditing && period != null) {
      return rangeStart != _initialRangeStart ||
          rangeEnd != _initialRangeEnd ||
          _notesController.text != _initialNotes;
    }
    return rangeStart != null &&
        rangeEnd != null &&
        (_notesController.text.isNotEmpty || _notesController.text != '');
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    focusedDay = widget.focusedDay ?? today;
    rangeStart = widget.focusedDay ?? today;
    if (isEditing && period != null) {
      rangeStart = period!.startDate;
      rangeEnd = period!.endDate;
      _notesController.text = period!.notes ?? '';
    }
    _initialRangeStart = rangeStart;
    _initialRangeEnd = rangeEnd;
    _initialNotes = _notesController.text;
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (_initialLoad && !isEditing && user != null && rangeStart != null) {
      _initialLoad = false;
      setState(() {
        rangeEnd = rangeStart!.add(Duration(days: user.periodLength - 1));
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Period' : 'Add Period',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
          onPressed: () {
            if (isPageDirty()) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text('Do you want to discard changes?'),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (isEditing && period != null)
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              color: Colors.white,
              tooltip: 'Delete Period',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Period'),
                    content: const Text(
                      'Are you sure you want to delete this period entry?',
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  ),
                );

                if (confirm == true) {
                  Navigator.of(context).pop();
                  await context.read<PeriodProvider>().deletePeriod(
                    period!.id!,
                  );
                  context.go('/');
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: ListView(
            children: [
              SectionTitle('Period Range'),
              TableCalendar(
                headerStyle: HeaderStyle(formatButtonVisible: false),
                startingDayOfWeek: StartingDayOfWeek.monday,
                firstDay: kFirstCalendarDay,
                lastDay: kLastCalendarDay,
                focusedDay: focusedDay,
                calendarFormat: CalendarFormat.month,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                rangeStartDay: rangeStart,
                rangeEndDay: rangeEnd,
                daysOfWeekHeight: kTableCalendarDaysOfTheWeekHeight,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  weekendStyle: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: Theme.of(context).colorScheme.secondary,
                  rangeStartDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeStartTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  withinRangeTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(child: Text('${day.day}')),
                    );
                  },
                ),

                onRangeSelected: (start, end, newFocusedDay) {
                  setState(() {
                    rangeStart = start;
                    rangeEnd = end;
                    focusedDay = newFocusedDay;
                  });
                },
                onDaySelected: (selectedDay, newFocusedDay) {
                  setState(() {
                    today = selectedDay;
                    focusedDay = newFocusedDay;
                  });
                },
              ),
              SectionTitle('Notes'),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Add notes about this period',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  ),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 50,
        margin: const EdgeInsets.all(10),
        child: TextButton(
          onPressed: () => _onSave(context),
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
          ),
          child: const Center(child: Text('Save')),
        ),
      ),
    );
  }
}
