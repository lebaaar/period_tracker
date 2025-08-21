import 'package:flutter/material.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/services/database_service.dart';

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
    return _periods.last.startDate.add(Duration(days: avgCycle.round()));
  }

  // Returns the current cycle day for a given date
  int getCurrentCycleDay([DateTime? date]) {
    // TODO - check logis
    if (_periods.isEmpty) return 0;
    date ??= DateTime.now();
    final lastPeriod = _periods.lastWhere(
      (p) => p.startDate.isBefore(date!),
      orElse: () => _periods.first,
    );
    return date.difference(lastPeriod.startDate).inDays + 1;
  }

  // Returns a status message (e.g., late, on track)
  String getStatusMessage() {
    final next = getNextPeriodDate();
    if (next == null) return 'Not enough data';
    final today = DateTime.now();
    if (today.isAfter(next)) {
      return 'Period is late';
    } else if (today.isAtSameMomentAs(next)) {
      return 'Period expected today';
    } else {
      return 'On track';
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
    List<int> cycles = [];
    for (int i = 1; i < _periods.length; i++) {
      cycles.add(
        _periods[i].startDate.difference(_periods[i - 1].startDate).inDays,
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
      return const Text('No data for this date');
    }

    // TODO - make pretty, follow figma
    return Center(
      child: Column(
        children: [
          Text(
            'Selected period: ${period.startDate.toIso8601String().split('T').first} - '
            '${period.endDate != null ? period.endDate!.toIso8601String().split('T').first : 'Ongoing'}',
          ),
          Text(notes),
          Text('Cycle Day: 	${getCurrentCycleDay(date)}'),
        ],
      ),
    );
  }
}
