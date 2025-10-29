import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/notification_type.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/utils/period_status_message_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Logic for handling notification taps in background - action button in notification
// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse response) {
//   if (response.actionId == 'log') {
//     navigatorKey.currentState?.pushNamed('/log');
//     print('log clicked in background!');
//     // You can also run Dart code to update DB, schedule new notifications, etc.
//   }
// }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DatabaseService _db = DatabaseService();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
        kNotificationChannelId,
        kNotificationChannelName,
        channelDescription: kNotificationChannelDescription,
        color: colorScheme.primary,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.private,
        // actions: <AndroidNotificationAction>[
        //   const AndroidNotificationAction(
        //     'log',
        //     'Log period',
        //     showsUserInterface: true,
        //   ),
        // ],
      );

  Future<void> init() async {
    // Init timezones
    tz.initializeTimeZones();
    // final String name = DateTime.now().timeZoneName;
    tz.setLocalLocation(tz.getLocation('Europe/Ljubljana')); // TODO

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/ic_stat_notify');

    await _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: androidInit),
      // onDidReceiveNotificationResponse: (NotificationResponse response) {
      //   if (response.actionId == 'log') {
      //     navigatorKey.currentState?.pushNamed('/log');
      //     print('log clicked');
      //   }
      // },
      // onDidReceiveBackgroundNotificationResponse:
      //     notificationTapBackground, // when app is in background or terminated
    );
  }

  /// Requests notification permissions (Android 13+).
  /// @return true if permissions are granted, false otherwise.
  Future<bool> requestPermissions() async {
    // Android 13+
    final androidPlugin = NotificationService()._flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidPlugin?.requestNotificationsPermission();
    if (granted != true) {
      return false;
    }
    return true; // permission granted or older Android version (granted == null)
  }

  /// Schedules a notification. Method should be called only if notifications are enabled.
  /// @param id Unique identifier for the notification.
  /// @param title Title of the notification.
  /// @param body Body text of the notification.
  /// @param scheduledDate Date and time when the notification should be shown.
  /// @param type Type of the notification (used for payload).
  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    NotificationType type,
  ) async {
    // Check if notifications are enabled
    final Settings settings = await _db.getSettings();
    bool notificationsEnabled = settings.notificationsEnabled;
    if (!notificationsEnabled) return;

    String? payload;
    if (type == NotificationType.logReminder ||
        type == NotificationType.periodToday) {
      payload = '/log';
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: _androidNotificationDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Schedules notifications for the next period.
  /// @param nextPeriodStartDate The start date of the next period.
  /// @param sendNotificationsDaysBefore Number of days before the period to send notifications.
  /// @param notificationTime Time of day to send the notifications.
  Future<void> scheduleNotificationsForNextPeriod(
    DateTime? nextPeriodStartDate,
    int sendNotificationsDaysBefore,
    TimeOfDay notificationTime,
  ) async {
    // Cancel existing notifications
    await cancelAllNotifications();

    if (nextPeriodStartDate == null) {
      await cancelAllNotifications();
      return;
    }

    if (nextPeriodStartDate.isBefore(DateTime.now())) return;

    // Schedule new notifications
    for (var i = 0; i <= sendNotificationsDaysBefore; i++) {
      final DateTime scheduledDate = DateTime(
        nextPeriodStartDate.year,
        nextPeriodStartDate.month,
        nextPeriodStartDate.day - i,
        notificationTime.hour,
        notificationTime.minute,
      );

      if (scheduledDate.isBefore(DateTime.now())) continue;

      String notificationTitle =
          PeriodStatusMessageHelper.getNotificationTitleMessage(i);
      String notificationBody =
          PeriodStatusMessageHelper.getNotificationBodyMessage(i);

      await scheduleNotification(
        i,
        notificationTitle,
        notificationBody,
        scheduledDate,
        i == 0 ? NotificationType.periodToday : NotificationType.upcomingPeriod,
      );
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Helper method to retrieve all pending notifications.
  /// @return A list of pending notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotifications;
  }
}
