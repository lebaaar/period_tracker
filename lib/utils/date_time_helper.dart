import 'package:flutter/material.dart';

class DateTimeHelper {
  static String displayDate(DateTime date) {
    date = date.toLocal();
    String year = date.year.toString();
    String month = date.month.toString();
    String day = date.day.toString();

    return '$day.$month.$year';
  }

  static String displayTime(TimeOfDay time) {
    String hour = time.hour.toString();
    if (hour == '0') {
      hour = '00';
    }
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool isFirstDayOfMonth(DateTime date) {
    return date.day == 1;
  }

  static bool isLastDayOfMonth(DateTime date) {
    final nextDay = date.add(const Duration(days: 1));
    return nextDay.day == 1;
  }
}
