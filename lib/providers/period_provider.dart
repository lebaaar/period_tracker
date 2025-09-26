import 'package:flutter/material.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/utils/period_status_message.dart';
import 'package:period_tracker/utils/period_status_message_helper.dart';

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

  int getCurrentCycleDay([DateTime? date]) {
    if (_periods.isEmpty) return 0;

    // Normalize to local
    date ??= DateTime.now();
    date = date.toLocal();

    _periods.sort((a, b) => a.startDate.compareTo(b.startDate));

    if (date.isBefore(_periods.first.startDate.toLocal())) {
      return 0;
    }

    // Find the most recent period that started before or on this date
    Period? lastPeriod;
    for (var p in _periods) {
      if (!date.isBefore(p.startDate.toLocal())) {
        lastPeriod = p;
      } else {
        break;
      }
    }

    if (lastPeriod == null) return 0;

    // If within that period
    final start = lastPeriod.startDate.toLocal();
    final end = lastPeriod.endDate?.toLocal();
    if (end == null || !date.isAfter(end)) {
      return date.difference(start).inDays + 1;
    }

    // If after that period ended count from start
    return date.difference(start).inDays + 1;
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
      status.text = 'Not enough data to predict the next period';
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

    return PeriodStatusMessageHelper.getPeriodStatusMessage(daysUntilNext);
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
    // find period for the date
    final checkDate = DateTime.utc(date.year, date.month, date.day);
    int cycleDay = getCurrentCycleDay(checkDate);
    // Selected date is before first period
    if (cycleDay <= 0) return Container();

    Period? period = PeriodService.getPeriodInDate(checkDate, periods);
    if (period == null) {
      return Text(
        'Cycle Day: ${getCurrentCycleDay(checkDate)}',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final String notes;
    if (period.notes != null && period.notes!.isNotEmpty) {
      notes = 'Notes: ${period.notes!}';
    } else {
      notes = 'No notes about this period';
    }

    return Center(
      child: Column(
        children: [
          Text(
            'Cycle Day: ${getCurrentCycleDay(checkDate)}',
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
