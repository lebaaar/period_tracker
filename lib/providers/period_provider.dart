import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:period_tracker/utils/date_time_helper.dart';

class PeriodProvider extends ChangeNotifier {
  /// Always sorted newest first. Never re-sorted in place by the getters below.
  List<Period> _periods = [];
  List<Period> get periods => _periods;
  final DatabaseService _db = DatabaseService();

  /// Completes after the first database load.
  late final Future<void> ready;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  PeriodProvider() {
    ready = fetchPeriods();
  }

  /// Provider without a database load, for unit tests.
  @visibleForTesting
  PeriodProvider.test() {
    ready = Future.value();
  }

  @visibleForTesting
  void setPeriodsForTest(List<Period> periods) {
    _periods = List<Period>.from(periods)..sort((a, b) => b.startDate.compareTo(a.startDate));
    _loaded = true;
  }

  /// Copy of the periods, oldest first.
  List<Period> get _oldestFirst => List<Period>.from(_periods)..sort((a, b) => a.startDate.compareTo(b.startDate));

  Future<void> fetchPeriods() async {
    _periods = await _db.getAllPeriods();
    _periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    _loaded = true;
    notifyListeners();
  }

  Future<void> insertPeriod(Period period) async {
    final int id = await _db.insertPeriod(period);
    // keep the database id so the entry can be edited or deleted right away
    _periods.add(Period(id: id, startDate: period.startDate, endDate: period.endDate, notes: period.notes));
    _periods.sort((a, b) => b.startDate.compareTo(a.startDate));
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

  /// Cycle length used for predictions, so every predicted date uses the same number.
  /// Dynamic: average of the last 6 cycles (falls back to the user's setting).
  int _predictedCycleLength(bool dynamicPeriodPrediction, int? userCycleLength) {
    if (dynamicPeriodPrediction) {
      final double? avg = getAverageCycleLength(useRecent6: true);
      if (avg != null) return avg.round();
    }
    return userCycleLength ?? kDefaultCycleLength;
  }

  /// Returns the next expected period start date.
  /// @param dynamicPeriodPrediction Whether to use the average of the last 6 cycles
  /// @param userCycleLength The user's set cycle length (used if dynamic prediction is off or there is too little data)
  /// @returns The predicted next period start date (a calendar day), or null if no period is logged
  DateTime? getNextPeriodDate(bool dynamicPeriodPrediction, int? userCycleLength) {
    if (_periods.isEmpty) return null;
    final DateTime lastStart = _periods.first.startDate;
    return lastStart.add(Duration(days: _predictedCycleLength(dynamicPeriodPrediction, userCycleLength)));
  }

  // Returns the next 3 expected period start dates
  List<DateTime> getNext3PeriodDates(bool dynamicPredictionMode, int? userCycleLength) {
    final DateTime? firstPeriod = getNextPeriodDate(dynamicPredictionMode, userCycleLength);
    if (firstPeriod == null) return [];

    final int cycleLength = _predictedCycleLength(dynamicPredictionMode, userCycleLength);
    return [for (int i = 0; i < 3; i++) firstPeriod.add(Duration(days: cycleLength * i))];
  }

  int getCurrentCycleDay([DateTime? date]) {
    if (_periods.isEmpty) return 0;

    final DateTime target = DateTimeHelper.stripTime(date ?? clock.now());

    // most recent period that started on or before the target day (newest first)
    for (final Period p in _periods) {
      if (!target.isBefore(p.startDate)) {
        return target.difference(p.startDate).inDays + 1;
      }
    }
    return 0; // before the first logged period
  }

  // Returns average period length in days
  double? getAveragePeriodLength({bool? useRecent6}) {
    // Only consider periods with both start and end dates
    final List<Period> completed = _oldestFirst.where((p) => p.endDate != null).toList();
    if (completed.isEmpty) return null;

    List<Period> periodsToUse = completed;
    if (useRecent6 == true && completed.length > 6) {
      periodsToUse = completed.sublist(completed.length - 6);
    }

    final lengths = periodsToUse.map((p) => p.endDate!.difference(p.startDate).inDays + 1).where((days) => days > 0).toList();
    if (lengths.isEmpty) return null;
    return lengths.reduce((a, b) => a + b) / lengths.length;
  }

  // Returns average cycle length in days
  double? getAverageCycleLength({int? userCycleLength, bool? useRecent6}) {
    if (_periods.isEmpty) return null;
    if (_periods.length < 2) {
      // not enough data to calculate average cycle length - use the user provided cycle length if available
      return userCycleLength?.toDouble();
    }
    final List<Period> sorted = _oldestFirst;
    if (useRecent6 == true && sorted.length > 6) {
      sorted.removeRange(0, sorted.length - 6);
    }
    final List<int> cycles = [for (int i = 1; i < sorted.length; i++) sorted[i].startDate.difference(sorted[i - 1].startDate).inDays];
    if (cycles.isEmpty) return null;
    return cycles.reduce((a, b) => a + b) / cycles.length;
  }

  Period? getPeriodById(int id) {
    for (final Period p in _periods) {
      if (p.id == id) return p;
    }
    return null;
  }
}
