import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/notification_type.dart';
import 'package:period_tracker/main.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // TODO: customize notification details
  final AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
        kNotificationChannelId,
        kNotificationChannelName,
        channelDescription: kNotificationChannelDescription,
        color: Color(0xFFFF91C5),
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
    tz.setLocalLocation(
      tz.getLocation('Europe/Ljubljana'),
    ); // TODO: device zone

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

  Future<void> requestPermissions() async {
    // Android 13+
    final androidPlugin = NotificationService()._flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    NotificationType type,
  ) async {
    if (await getNotificationEnabled() == false) return;

    String? payload;
    if (type == NotificationType.logReminder ||
        type == NotificationType.periodToday) {
      payload = '/log';
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: _androidNotificationDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: payload,
    );
  }

  Future<void> scheduleNotificationsForNextPeriod(
    DateTime nextPeriodDate,
    int sendNotificationsDaysBefore,
    TimeOfDay notificationTime,
  ) async {
    // Cancel existing notifications
    await cancelAllNotifications();

    // Schedule new notifications
    for (var i = 0; i <= sendNotificationsDaysBefore; i++) {
      final DateTime scheduledDate = DateTime(
        nextPeriodDate.year,
        nextPeriodDate.month,
        nextPeriodDate.day - i,
        notificationTime.hour,
        notificationTime.minute,
      );

      if (!scheduledDate.isAfter(DateTime.now())) continue;

      await scheduleNotification(
        i,
        i == 0 ? 'Period Today' : 'Upcoming Period',
        i == 0
            ? 'Your period is expected to start today.'
            : 'Your period is expected to start in $i days',
        scheduledDate,
        i == 0 ? NotificationType.periodToday : NotificationType.upcomingPeriod,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
