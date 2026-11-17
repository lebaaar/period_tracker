import 'package:flutter/material.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/stepper_field.dart';
import 'package:provider/provider.dart';

/// Shared by the Settings tab and the standalone notifications page.
class ReminderActions {
  static DateTime? _nextPeriod(BuildContext context, Settings settings) {
    final User? user = context.read<UserProvider>().user;
    return context.read<PeriodProvider>().getNextPeriodDate(settings.predictionMode == 'dynamic', user?.cycleLength);
  }

  static Future<void> editDaysBefore(BuildContext context, Settings settings) async {
    final SettingsProvider provider = context.read<SettingsProvider>();
    final DateTime? next = _nextPeriod(context, settings);
    final int? days = await showNumberSheet(
      context: context,
      title: 'Remind me before',
      message: 'How many days before your period starts. 0 reminds you on the day.',
      initial: settings.notificationDaysBefore,
      min: 0,
      max: kMaxNotificationsDaysBefore,
    );
    if (days == null) return;
    await provider.updateSettings(notificationDaysBefore: days);
    await NotificationService().scheduleNotificationsForNextPeriod(next, days, settings.notificationTime);
  }

  static Future<void> editTime(BuildContext context, Settings settings) async {
    final SettingsProvider provider = context.read<SettingsProvider>();
    final DateTime? next = _nextPeriod(context, settings);
    final TimeOfDay? time = await showTimeSheet(
      context: context,
      title: 'Reminder time',
      message: 'When you get the reminder on the day.',
      initial: settings.notificationTime,
    );
    if (time == null) return;
    await provider.updateSettings(notificationTime: time);
    await NotificationService().scheduleNotificationsForNextPeriod(next, settings.notificationDaysBefore, time);
  }
}
