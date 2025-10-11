// UI
import 'package:flutter/rendering.dart';
import 'package:period_tracker/theme.dart';

final double kBorderRadius = 12;
final double kTableCalendarDaysOfTheWeekHeight = 30;

// Date constants for calendar range
final DateTime kFirstCalendarDay = DateTime.utc(2020, 1, 1);
final DateTime kLastCalendarDay = DateTime.utc(DateTime.now().year + 8, 12, 31);

// table_calendar specific
// logged period gradients - gradient the whole background
final Gradient kLoggedPeriodFirstMonthDayGradient = LinearGradient(
  colors: [colorScheme.surface, colorScheme.secondary],
  stops: [0.0, 0.33],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
final Gradient kLoggedPeriodLastMonthDayGradient = LinearGradient(
  colors: [colorScheme.secondary, colorScheme.surface],
  stops: [0.66, 1.0],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// logged selected period gradients - gradient the whole background
final Gradient kLoggedSelectedPeriodFirstMonthDayGradient = LinearGradient(
  colors: [colorScheme.surface, colorScheme.primary],
  stops: [0.0, 0.33],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
final Gradient kLoggedSelectedPeriodLastMonthDayGradient = LinearGradient(
  colors: [colorScheme.primary, colorScheme.surface],
  stops: [0.66, 1.0],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// TODO: upcoming period gradients - gradient just the border
final Gradient kUpcomingSelectedPeriodFirstMonthDayGradient = LinearGradient(
  colors: [colorScheme.surface, colorScheme.primary],
  stops: [0.0, 0.33],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
final Gradient kUpcomingSelectedPeriodLastMonthDayGradient = LinearGradient(
  colors: [colorScheme.primary, colorScheme.surface],
  stops: [0.66, 1.0],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Default cycle and period lengths
final int kDefaultCycleLength = 28;
final int kDefaultPeriodLength = 5;
final int kMinCycleLength = 7;
final int kMaxCycleLength = 90;
final int kMinPeriodLength = 1;
final int kMaxPeriodLength = 15;
final int kMinDaysBetweenPeriods = 2;

// Default user name
final String kMysteriousUserName = 'Mysterious User';

// Database constants
final String kDatabaseName = 'period_tracker.db';
final String kPeriodsTableName = 'periods';
final String kUserTableName = 'user';
final String kSettingsTableName = 'settings';
final String kNotificationsTableName = 'notifications';

// Notification constants
final String kNotificationChannelId = 'period_tracker_channel';
final String kNotificationChannelName = 'Period Tracker Notifications';
final String kNotificationChannelDescription =
    'Notifications for Period Tracker';
final int kDefaultNotificationsDaysBefore = 3;
final int kMaxNotificationsDaysBefore = 14;
final int kDefaultNotificationHour = 8;

// Backup constants
final String kBackupFileName = 'data.period';
final String kBackupMimeType = 'application/json';
final String kBackupEmailTitle = 'Period Tracker backup';
final String kBackupEmailText =
    '''Attached is your Period Tracker $kBackupFileName file, which contains all your data.

To restore your data on a new device:
1. Save the attached $kBackupFileName file on your new device.
2. Locate the file using a file manager app and open it with the Period Tracker app.
4. TODO - Follow instructions...
5. Confirm to restore your data.''';
