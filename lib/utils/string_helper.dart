import 'package:flutter/material.dart';

class StringHelper {
  static String displayTime(TimeOfDay time) {
    String hour = time.hour.toString();
    if (hour == '0') {
      hour = '00';
    }
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
