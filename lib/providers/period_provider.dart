import 'package:flutter/material.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/utils/period_status_message.dart';

class PeriodProvider extends ChangeNotifier {
  List<Period> _periods = [];
  List<Period> get periods => _periods;
  final DatabaseService _db = DatabaseService();

  PeriodProvider() {
    fetchPeriods();
  }

  Future<void> fetchPeriods() async {
    _periods = await _db.getAllPeriods();
    _periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    notifyListeners();
  }

  Future<void> insertPeriod(Period period) async {
    await _db.insertPeriod(period);
    _periods.add(period);
    notifyListeners();
  }

  Future<void> deletePeriod(int id) async {
    await _db.deletePeriod(id);
    _periods.removeWhere((period) => period.id == id);
    notifyListeners();
  }

  Future<void> updatePeriod(Period period) async {
    await _db.updatePeriod(period);
    await fetchPeriods();
  }

  // Returns the next expected period start date based on average cycle length
  DateTime? getNextPeriodDate() {
    if (_periods.length < 2) return null;
    final avgCycle = getAverageCycleLength();
    if (avgCycle == null) return null;
    // _periods is sorted descending by startDate, so _periods.first is the most recent
    return _periods.first.startDate.add(Duration(days: avgCycle.round()));
  }

  // Returns the current cycle day for a given date
  int getCurrentCycleDay([DateTime? date]) {
    if (_periods.isEmpty) return 0;
    date ??= DateTime.now();
    final lastPeriod = _periods
        .where((p) => !p.startDate.isAfter(date!))
        .fold<Period?>(
          null,
          (prev, p) =>
              prev == null || p.startDate.isAfter(prev.startDate) ? p : prev,
        );
    if (lastPeriod == null) return 0;
    return date.difference(lastPeriod.startDate).inDays + 1;
  }

  // Returns a status message (e.g., late, on track)
  PeriodStatusMessage getStatusMessage(Color defaultColor) {
    PeriodStatusMessage status = PeriodStatusMessage(
      text: '',
      color: defaultColor,
    );

    final next = getNextPeriodDate();
    if (_periods.length < 2 || next == null) {
      status.text = 'Not enough data to predict next period';
      return status;
    }
    status.color = Colors.green;

    final today = DateTime.now();
    final ongoing = _periods.any(
      (p) =>
          !today.isBefore(p.startDate) &&
          (p.endDate == null || !today.isAfter(p.endDate!)),
    );
    if (ongoing) {
      status.text = 'Currently in period';
      return status;
    }

    final difference = next
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (difference > 0) {
      status.text = 'Next period in $difference days';
      return status;
    } else if (difference < 0) {
      if (difference < -1) {
        status.text = 'Period is ${-difference} days late';
      } else {
        status.text = 'Period is 1 day late';
      }
      status.color = Colors.red;
      return status;
    } else {
      status.text = 'Period is due today';
      return status;
    }
  }

  // Returns average period length in days
  // TODO - fix logic
  double? getAveragePeriodLength() {
    // Only consider periods with both start and end dates
    final completed = _periods.where((p) => p.endDate != null).toList();
    if (completed.isEmpty) return null;
    final lengths = completed
        .map((p) => p.endDate!.difference(p.startDate).inDays + 1)
        .where((days) => days > 0)
        .toList();
    if (lengths.isEmpty) return null;
    return lengths.reduce((a, b) => a + b) / lengths.length;
  }

  // Returns average cycle length in days
  double? getAverageCycleLength() {
    if (_periods.length < 2) return null;
    final sorted = List<Period>.from(_periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    List<int> cycles = [];
    for (int i = 1; i < sorted.length; i++) {
      cycles.add(
        sorted[i].startDate.difference(sorted[i - 1].startDate).inDays,
      );
    }
    if (cycles.isEmpty) return null;
    return cycles.reduce((a, b) => a + b) / cycles.length;
  }

  Period? getPeriodById(int id) {
    try {
      return _periods.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Returns a widget or data for a specific date (customize as needed)
  Widget getDataForDate(DateTime date, BuildContext context) {
    final period = _periods.firstWhere(
      (p) =>
          !date.isBefore(p.startDate) &&
          (p.endDate == null || !date.isAfter(p.endDate!)),
      orElse: () => Period(startDate: date),
    );

    final String notes;
    if (period.notes != null && period.notes!.isNotEmpty) {
      notes = 'Notes: ${period.notes!}';
    } else {
      notes = 'No notes about this period';
    }

    if (period.id == null) {
      return Text(
        'Cycle Day: 	${getCurrentCycleDay(date)}',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    // TODO - make pretty, follow figma
    return Center(
      child: Column(
        children: [
          Text(
            'Cycle Day: ${getCurrentCycleDay(date)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 4),
          Text(
            'Selected period: ${DateTimeHelper.displayDate(period.startDate)} - '
            '${period.endDate != null ? DateTimeHelper.displayDate(period.endDate!) : 'Ongoing'}',
          ),
          SizedBox(height: 4),
          Text(notes),
        ],
      ),
    );
  }
}
