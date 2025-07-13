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
}
