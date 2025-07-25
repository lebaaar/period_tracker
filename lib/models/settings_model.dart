import 'package:flutter/material.dart';

class Settings {
  final int? id;
  final String predictionMode;
  final bool darkMode;
  final bool notificationEnabled;
  final int notificationDaysBefore;
  final TimeOfDay notificationTime;

  Settings({
    this.id,
    required this.predictionMode,
    required this.darkMode,
    required this.notificationEnabled,
    required this.notificationDaysBefore,
    required this.notificationTime,
  });

  factory Settings.fromMap(Map<String, dynamic> map) {
    // parse notificationTime
    final timeParts = (map['notificationTime'] as String).split(':');
    final notificationTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return Settings(
      id: map['id'] as int?,
      predictionMode: map['predictionMode'] as String,
      darkMode: map['darkMode'] == 1,
      notificationEnabled: map['notificationEnabled'] == 1,
      notificationDaysBefore: map['notificationDaysBefore'] as int,
      notificationTime: notificationTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'predictionMethod': predictionMode,
      'darkMode': darkMode,
      'notificationEnabled': notificationEnabled,
      'notificationDaysBefore': notificationDaysBefore,
      'notificationTimeHour': notificationTime.hour,
      'notificationTimeMinute': notificationTime.minute,
    };
  }

  @override
  String toString() {
    return 'Settings(id: $id, predictionMode: $predictionMode, darkMode: $darkMode, notificationEnabled: $notificationEnabled, notificationDaysBefore: $notificationDaysBefore, notificationTime: $notificationTime)';
  }
}
