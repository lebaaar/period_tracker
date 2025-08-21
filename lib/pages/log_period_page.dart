import 'package:flutter/material.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
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

  bool get isEditing => widget.isEditing;
  Period? get period => widget.period;

  void _onSave(BuildContext context) {
    if (rangeStart == null || rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a period range'),
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
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          // TODO: ask if user wants to discard changes if page is dirty
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            _buildTitle('Period Range'),
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
            _buildTitle('Notes'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Add any notes about this period...',
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
            Text('isEditing: $isEditing\nperiod: $period.'),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 50,
        margin: const EdgeInsets.all(10),
        child: ElevatedButton(
          onPressed: () => _onSave(context),
          style: ElevatedButton.styleFrom(
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

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
        ),
      ),
    );
  }
}
