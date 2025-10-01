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

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool dayBetweenDates(
    DateTime checkDate,
    DateTime startDate,
    DateTime endDate,
  ) {
    checkDate = stripTime(checkDate);
    startDate = stripTime(startDate);
    endDate = stripTime(endDate);

    return (checkDate.isAtSameMomentAs(startDate) ||
            checkDate.isAfter(startDate)) &&
        (checkDate.isAtSameMomentAs(endDate) || checkDate.isBefore(endDate));
  }

  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
