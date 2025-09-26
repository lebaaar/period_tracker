import 'package:flutter/material.dart';
import 'package:period_tracker/utils/period_status_message.dart';

class PeriodStatusMessageHelper {
  static PeriodStatusMessage getPeriodStatusMessage(int daysUntilNextPeriod) {
    PeriodStatusMessage status = PeriodStatusMessage(
      text: '',
      color: Colors.green,
    );
    if (daysUntilNextPeriod < 0) {
      status.text =
          "Period is ${-daysUntilNextPeriod} day${-daysUntilNextPeriod != 1 ? 's' : ''} late";
      status.color = Colors.red;
      return status;
    } else if (daysUntilNextPeriod == 0) {
      status.text = "Period is due today";
      return status;
    } else if (daysUntilNextPeriod == 1) {
      status.text = "Period expected tomorrow";
      return status;
    } else {
      status.text = "Period expected in $daysUntilNextPeriod days";
      return status;
    }
  }

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
