import 'package:flutter/material.dart';

class StringHelper {
  static String displayTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
