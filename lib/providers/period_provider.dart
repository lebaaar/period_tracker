import 'package:flutter/material.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:period_tracker/utils/date_time_helper.dart';

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
  String getStatusMessage() {
    final next = getNextPeriodDate();
    if (_periods.isEmpty) {
      return 'No period data available';
    }
    if (next == null) {
      return 'Not enough data to predict next period';
    }
    final today = DateTime.now();
    // Check if currently in an ongoing period
    final ongoing = _periods.any(
      (p) =>
          !today.isBefore(p.startDate) &&
          (p.endDate == null || !today.isAfter(p.endDate!)),
    );
    if (ongoing) {
      return 'Currently in period';
    }
    if (today.isAfter(next)) {
      final daysLate = today.difference(next).inDays;
      return daysLate == 1
          ? 'Period is 1 day late'
          : 'Period is $daysLate days late';
    } else if (today.isAtSameMomentAs(next)) {
      return 'Period expected today';
    } else {
      final daysLeft = next.difference(today).inDays;
      return daysLeft == 1
          ? 'Period expected tomorrow'
          : 'Period expected in $daysLeft days';
    }
  }

  // Returns average period length in days
  double? getAveragePeriodLength() {
    if (_periods.isEmpty) return null;
    final lengths = _periods
        .where((p) => p.isCompleted)
        .map((p) => p.lengthInDays());
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

  // Returns a widget or data for a specific date (customize as needed)
  Widget getDataForDate(DateTime date) {
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
      notes = 'No notes';
    }

    if (period.id == null) {
      return Text('Cycle Day: 	${getCurrentCycleDay(date)}');
    }

    // TODO - make pretty, follow figma
    return Center(
      child: Column(
        children: [
          Text(
            'Selected period: ${DateTimeHelper.displayDate(period.startDate)} - '
            '${period.endDate != null ? DateTimeHelper.displayDate(period.endDate!) : 'Ongoing'}',
          ),
          Text(notes),
          Text('Cycle Day: ${getCurrentCycleDay(date)}'),
        ],
      ),
    );
  }
}
