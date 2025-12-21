import 'package:flutter/material.dart';

class DateTimeHelper {
  static String displayDate(DateTime date) {
    final DateTime localDate = date.toLocal();
    final String year = localDate.year.toString();
    final String month = localDate.month.toString();
    final String day = localDate.day.toString();

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
    final DateTime nextDay = date.add(const Duration(days: 1));
    return nextDay.day == 1;
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  static bool dayBetweenDates(DateTime checkDate, DateTime startDate, DateTime endDate) {
    final DateTime strippedCheckDate = stripTime(checkDate);
    final DateTime strippedStartDate = stripTime(startDate);
    final DateTime strippedEndDate = stripTime(endDate);

    return (strippedCheckDate.isAtSameMomentAs(strippedStartDate) || strippedCheckDate.isAfter(strippedStartDate)) &&
        (strippedCheckDate.isAtSameMomentAs(strippedEndDate) || strippedCheckDate.isBefore(strippedEndDate));
  }

  static DateTime stripTime(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
