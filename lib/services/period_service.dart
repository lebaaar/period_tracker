import 'package:period_tracker/models/period_model.dart';

class PeriodService {
  static bool validateCycleLength(int? cycleLength) {
    if (cycleLength == null ||
        cycleLength.isNegative ||
        cycleLength > 60 ||
        cycleLength < 15) {
      return false;
    }
    return true;
  }

  static bool validatePeriodLength(int? periodLength) {
    if (periodLength == null ||
        periodLength.isNegative ||
        periodLength > 10 ||
        periodLength < 2) {
      return false;
    }
    return true;
  }

  static bool isOverlappingPeriod(
    DateTime newStartDate,
    List<Period> periods, {
    DateTime? newEndDate,
  }) {
    final endDate = newEndDate ?? newStartDate;
    for (final period in periods) {
      final start = period.startDate;
      final end = period.endDate ?? period.startDate;
      if (!(endDate.isBefore(start) || newStartDate.isAfter(end))) {
        return true;
      }
    }
    return false;
  }

  static bool checkPeriodInFuture(DateTime startDate, DateTime? endDate) {
    final now = DateTime.now();
    if (startDate.isAfter(now)) return true;
    if (endDate != null && endDate.isAfter(now)) return true;
    return false;
  }
}
