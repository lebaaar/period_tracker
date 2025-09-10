import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';

class PeriodService {
  static bool validateCycleLength(int? cycleLength) {
    if (cycleLength == null ||
        cycleLength.isNegative ||
        cycleLength > kMaxCycleLength ||
        cycleLength < kMinCycleLength) {
      return false;
    }
    return true;
  }

  static bool validatePeriodLength(int? periodLength) {
    if (periodLength == null ||
        periodLength.isNegative ||
        periodLength > kMaxPeriodLength ||
        periodLength < kMinPeriodLength) {
      return false;
    }
    return true;
  }

  static bool isOverlappingPeriod(
    DateTime newStartDate,
    List<Period> periods, {
    DateTime? newEndDate,
    int? excludeId,
  }) {
    final endDate = newEndDate ?? newStartDate;
    for (final period in periods) {
      if (excludeId != null && period.id == excludeId) continue;
      final start = period.startDate;
      final end = period.endDate ?? period.startDate;
      // Overlap if ranges intersect (inclusive)
      if (!(endDate.isBefore(start) || newStartDate.isAfter(end))) {
        return true;
      }
    }
    return false;
  }

  static bool isInPeriod(DateTime day, List<Period> periods) {
    final checkDay = DateTime.utc(day.year, day.month, day.day);
    Period? period = getPeriodInDate(checkDay, periods);
    if (period != null) return true;
    return false;
  }

  static bool isStartDay(DateTime day, List<Period> periods) {
    return periods.any(
      (p) =>
          p.startDate.year == day.year &&
          p.startDate.month == day.month &&
          p.startDate.day == day.day,
    );
  }

  static bool isEndDay(DateTime day, List<Period> periods) {
    return periods.any(
      (p) =>
          p.endDate != null &&
          p.endDate!.year == day.year &&
          p.endDate!.month == day.month &&
          p.endDate!.day == day.day,
    );
  }

  static Period? getPeriodInDate(DateTime date, List<Period> periods) {
    final checkDate = DateTime.utc(date.year, date.month, date.day);
    Period? period;
    for (var p in periods) {
      final periodStart = DateTime.utc(
        p.startDate.year,
        p.startDate.month,
        p.startDate.day,
      );
      // hardcoded period.endDate! - no support for ongoing periods in v1
      final periodEnd = DateTime.utc(
        p.endDate!.year,
        p.endDate!.month,
        p.endDate!.day,
      );

      if (checkDate.isAtSameMomentAs(periodStart) ||
          checkDate.isAtSameMomentAs(periodEnd) ||
          (checkDate.isAfter(periodStart) && checkDate.isBefore(periodEnd))) {
        period = p;
        break;
      }
    }
    return period;
  }
}
