class PeriodStatusMessageHelper {
  static String getNotificationTitleMessage(int daysUntilNextPeriod) {
    if (daysUntilNextPeriod == 0) {
      return 'Period expected today';
    } else {
      return 'Upcoming period';
    }
  }

  static String getNotificationBodyMessage(int daysUntilNextPeriod) {
    if (daysUntilNextPeriod == 0) {
      return 'Your period is expected to start today.';
    } else if (daysUntilNextPeriod == 1) {
      return 'Your period is expected to start tomorrow.';
    } else {
      return 'Your period is expected to start in $daysUntilNextPeriod days.';
    }
  }
}
