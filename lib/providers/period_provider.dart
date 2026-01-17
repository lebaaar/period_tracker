import 'package:flutter/material.dart';
import 'package:period_tracker/constants.dart';
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

  /// Returns the next expected period start date based on the last 6 logged periods average cycle length
  /// @param dynamicPeriodPrediction Whether to use dynamic prediction based on average cycle length
  /// @param userCycleLength The user's set cycle length (used if dynamic prediction is false)
  /// @returns The predicted next period start date, or null if not enough data
  DateTime? getNextPeriodDate(bool dynamicPeriodPrediction, int? userCycleLength) {
    if (periods.isEmpty) return null;
    if (periods.length < 2) {
      // Not enough data to predict next period - only one period logged
      // Use the provided userCycleLength
      // Case when user gets not enough data to predict the next period right after onboarding
      return periods.last.startDate.add(Duration(days: userCycleLength ?? kDefaultCycleLength));
    }
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    if (dynamicPeriodPrediction) {
      // dynamic prediction based on average cycle length
      final avgCycle = getAverageCycleLength(useRecent6: true);
      if (avgCycle == null) return null;
      return periods.last.startDate.add(Duration(days: avgCycle.round()));
    } else {
      // static prediction based on last period and user's cycle length
      if (userCycleLength == null) return null;
      return periods.last.startDate.add(Duration(days: userCycleLength));
    }
  }

  // Returns the next 3 expected period start dates
  List<DateTime> getNext3PeriodDates(bool dynamicPredictionMode, int? userCycleLength) {
    final List<DateTime> upcomingPeriods = [];

    final DateTime? firstPeriod = getNextPeriodDate(dynamicPredictionMode, userCycleLength);
    if (firstPeriod == null) return upcomingPeriods;

    upcomingPeriods.add(firstPeriod);

    // Calculate cycle length based on mode
    final int cycleLength;
    if (dynamicPredictionMode) {
      final double? avgCycle = getAverageCycleLength();
      cycleLength = avgCycle?.round() ?? userCycleLength ?? kDefaultCycleLength;
    } else {
      cycleLength = userCycleLength ?? kDefaultCycleLength;
    }

    // Add the next 2 periods
    for (int i = 1; i < 3; i++) {
      upcomingPeriods.add(firstPeriod.add(Duration(days: cycleLength * i)));
    }

    return upcomingPeriods;
  }

  int getCurrentCycleDay([DateTime? date]) {
    if (_periods.isEmpty) return 0;

    // Normalize to UTC date only (strip time)
    date ??= DateTime.now();
    final targetDate = DateTime.utc(date.year, date.month, date.day);

    _periods.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Normalize period dates to UTC date only for consistent comparison
    final normalizedPeriods = _periods.map((p) {
      final DateTime startDate = DateTime.utc(p.startDate.year, p.startDate.month, p.startDate.day);
      final DateTime? endDate = p.endDate != null ? DateTime.utc(p.endDate!.year, p.endDate!.month, p.endDate!.day) : null;
      return {'period': p, 'start': startDate, 'end': endDate};
    }).toList();

    // Check if target date is before the first period
    if (targetDate.isBefore(normalizedPeriods.first['start'] as DateTime)) {
      return 0;
    }

    // Find the most recent period that started before or on this date
    Map<String, dynamic>? lastPeriodData;
    for (var periodData in normalizedPeriods) {
      final startDate = periodData['start'] as DateTime;
      if (targetDate.isAtSameMomentAs(startDate) || targetDate.isAfter(startDate)) {
        lastPeriodData = periodData;
      } else {
        break;
      }
    }

    if (lastPeriodData == null) return 0;

    final DateTime start = lastPeriodData['start'] as DateTime;

    // Calculate days from the start of the most recent period
    final int daysSinceStart = targetDate.difference(start).inDays + 1;

    // Ensure we return at least day 1 if we're on or after the start date
    return daysSinceStart > 0 ? daysSinceStart : 1;
  }

  // Returns a status message (e.g., late, on track)
  PeriodStatusMessage getStatusMessage(Color defaultColor, DateTime? nextPeriodDate) {
    PeriodStatusMessage status = PeriodStatusMessage(text: '', color: defaultColor);

    if (_periods.isEmpty || nextPeriodDate == null) {
      // in this case status bar on home page is hidden
      status.text = 'Start by tapping the + button below to log your most recent period';
      return status;
    }

    status.color = Colors.green;

    final List<Period> sortedPeriods = List<Period>.from(_periods)..sort((a, b) => a.startDate.compareTo(b.startDate));

    final lastPeriod = sortedPeriods.last; // last period dates are normalized to UTC already

    // ensure both nextPeriodDate and today are stripped of time and in UTC
    final DateTime now = DateTime.now();
    final DateTime today = DateTime.utc(now.year, now.month, now.day);

    // Check if currently in period
    if ((today.isAtSameMomentAs(lastPeriod.startDate) || today.isAtSameMomentAs(lastPeriod.endDate!)) ||
        (today.isAfter(lastPeriod.startDate) && today.isBefore(lastPeriod.endDate!))) {
      status.text = 'Currently in period';
      return status;
    }

    final int diff = nextPeriodDate.difference(today).inDays;
    return PeriodStatusMessageHelper.getPeriodStatusMessage(diff);
  }

  // Returns average period length in days
  double? getAveragePeriodLength({bool? useRecent6}) {
    // Only consider periods with both start and end dates
    final completed = _periods.where((p) => p.endDate != null).toList();
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
    if (periods.isEmpty) return null;
    if (periods.length < 2) {
      // not enough data to calculate average cycle length - use the user provided cycle length if available
      // returns null if userCycleLength is null
      return userCycleLength?.toDouble();
    }
    final List<Period> sorted = List<Period>.from(periods)..sort((a, b) => a.startDate.compareTo(b.startDate));
    final List<int> cycles = [];
    if (useRecent6 == true && sorted.length > 6) {
      sorted.removeRange(0, sorted.length - 6);
    }
    for (int i = 1; i < sorted.length; i++) {
      cycles.add(sorted[i].startDate.difference(sorted[i - 1].startDate).inDays);
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
    final DateTime checkDate = DateTime.utc(date.year, date.month, date.day);
    final int cycleDay = getCurrentCycleDay(checkDate);
    // Selected date is before first period
    if (cycleDay <= 0) return Container();

    final Period? period = PeriodService.getPeriodInDate(checkDate, periods);
    if (period == null) {
      return Text('Cycle Day: $cycleDay', style: Theme.of(context).textTheme.bodyMedium);
    }

    final String? notes;
    if (period.notes != null && period.notes!.isNotEmpty) {
      notes = 'Notes: ${period.notes!}';
    } else {
      notes = null;
    }

    return Center(
      child: Column(
        children: [
          Text('Cycle Day: $cycleDay', style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 4),
          Text(
            'Selected period: ${DateTimeHelper.displayDate(period.startDate)} - '
            '${period.endDate != null ? DateTimeHelper.displayDate(period.endDate!) : 'Ongoing'}',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          if (notes != null) Text(notes, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
