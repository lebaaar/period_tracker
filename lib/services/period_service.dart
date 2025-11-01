import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';

class PeriodService {
  static bool validateCycleLength(int? cycleLength) {
    if (cycleLength == null || cycleLength.isNegative || cycleLength > kMaxCycleLength || cycleLength < kMinCycleLength) {
      return false;
    }
    return true;
  }

  /// Validates if the period length is within acceptable bounds.
  /// @param periodLength The length of the period to validate.
  /// @returns true if valid, false otherwise.
  static bool validatePeriodLength(int? periodLength) {
    if (periodLength == null || periodLength.isNegative || periodLength > kMaxPeriodLength || periodLength < kMinPeriodLength) {
      return false;
    }
    return true;
  }

  /// Checks if the new period overlaps with existing periods.
  /// @param newStartDate The start date of the new period.
  /// @param periods The list of logged periods.
  /// @param newEndDate (Optional) The end date of the new period.
  /// @param excludeId (Optional) Period ID to exclude from the overlap check (useful for updates).
  /// @returns true if there is an overlap, false otherwise.
  static bool isOverlappingPeriod(DateTime newStartDate, List<Period> periods, {DateTime? newEndDate, int? excludeId}) {
    final DateTime endDate = newEndDate ?? newStartDate;
    for (final Period period in periods) {
      if (excludeId != null && period.id == excludeId) continue;
      final DateTime start = period.startDate;
      final DateTime end = period.endDate ?? period.startDate;
      // Overlap if ranges intersect (inclusive)
      if (!(endDate.isBefore(start) || newStartDate.isAfter(end))) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the given day is the start day of any period in the list.
  /// @param day The day to check.
  /// @param periods The list of logged periods.
  /// @returns true if the day is a start day, false otherwise.
  static bool isStartDay(DateTime day, List<Period> periods) {
    return periods.any((p) => p.startDate.year == day.year && p.startDate.month == day.month && p.startDate.day == day.day);
  }

  /// Checks if the given day is the end day of any period in the list.
  /// @param day The day to check.
  /// @param periods The list of logged periods.
  /// @returns true if the day is an end day, false otherwise.
  static bool isEndDay(DateTime day, List<Period> periods) {
    return periods.any((p) => p.endDate != null && p.endDate!.year == day.year && p.endDate!.month == day.month && p.endDate!.day == day.day);
  }

  /// Retrieves the logged period that includes the specified date.
  /// @param date The date to check.
  /// @param periods The list of logged periods.
  /// @returns The period that includes the date, or null if none found.
  static Period? getPeriodInDate(DateTime date, List<Period> periods) {
    final DateTime checkDate = DateTime.utc(date.year, date.month, date.day);
    Period? period;
    for (final Period p in periods) {
      final DateTime periodStart = DateTime.utc(p.startDate.year, p.startDate.month, p.startDate.day);
      // hardcoded period.endDate! - no support for ongoing periods in v1
      final DateTime periodEnd = DateTime.utc(p.endDate!.year, p.endDate!.month, p.endDate!.day);

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
