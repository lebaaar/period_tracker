import 'package:flutter/material.dart';
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
    // TODO - support on going periods
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

    // Check if period is in the future
    final isInFuture = PeriodService.checkPeriodInFuture(
      rangeStart!,
      rangeEnd,
    ); // TODO - support ongoing periods
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

    // Check if editing an existing period
    if (isEditing && period != null) {
      final updatedPeriod = Period(
        id: period!.id,
        startDate: rangeStart!,
        endDate: rangeEnd!,
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
    // TODO set ranges
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
                  await context.read<PeriodProvider>().deletePeriod(
                    period!.id!,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),

      body: SafeArea(
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
              calendarStyle: CalendarStyle(
                rangeHighlightColor: Colors.grey.shade900,
                rangeStartDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                withinRangeTextStyle: const TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface, // Use normal text color
                ),
              ),
              calendarBuilders: CalendarBuilders(
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
                    borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Center(child: Text('Save')),
        ),
      ),
    );
  }
}
