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
  DateTime? getNextPeriodDate(
    bool dynamicPeriodPrediction,
    int? userCycleLength,
  ) {
    if (_periods.length < 2) return null;
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    if (dynamicPeriodPrediction) {
      // dynamic prediction based on average cycle length
      final avgCycle = getAverageCycleLength();
      if (avgCycle == null) return null;
      return _periods.last.startDate.add(Duration(days: avgCycle.round()));
    } else {
      // static prediction based on last period and user's cycle length
      if (userCycleLength == null) return null;
      return _periods.last.startDate.add(Duration(days: userCycleLength));
    }
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
  PeriodStatusMessage getStatusMessage(
    Color defaultColor,
    DateTime? nextPeriodDate,
  ) {
    PeriodStatusMessage status = PeriodStatusMessage(
      text: '',
      color: defaultColor,
    );

    if (_periods.length < 2 || nextPeriodDate == null) {
      status.text = 'Not enough data to predict next period';
      return status;
    }
    status.color = Colors.green;

    _periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    final lastPeriod = _periods.last;
    final lastStart = DateTime(
      lastPeriod.startDate.year,
      lastPeriod.startDate.month,
      lastPeriod.startDate.day,
    );
    final lastEnd = DateTime(
      lastPeriod.endDate!.year,
      lastPeriod.endDate!.month,
      lastPeriod.endDate!.day,
    );
    final now = DateTime.now();
    final DateTime today = DateTime.utc(now.year, now.month, now.day);

    // Check if currently in period
    if (today.isAfter(lastStart.subtract(Duration(days: 1))) &&
        today.isBefore(lastEnd.add(Duration(days: 1)))) {
      status.text = 'Currently in period';
      return status;
    }

    final daysUntilNext = nextPeriodDate.difference(today).inDays;

    if (daysUntilNext < 0) {
      status.text =
          "Period is ${-daysUntilNext} day${-daysUntilNext != 1 ? 's' : ''} late";
      status.color = Colors.red;
      return status;
    } else if (daysUntilNext == 0) {
      status.text = "Period is due today";
      return status;
    } else if (daysUntilNext == 1) {
      status.text = "Period expected tomorrow";
      return status;
    } else {
      status.text = "Period expected in $daysUntilNext days";
      return status;
    }
  }

  // Returns average period length in days
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
