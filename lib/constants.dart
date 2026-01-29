import 'package:flutter/rendering.dart';
import 'package:period_tracker/theme.dart';

const String kPackageName = 'com.lebaaar.period_tracker';

// UI
const double kBorderRadius = 12;
const double kTableCalendarDaysOfTheWeekHeight = 30;

// Date constants for calendar range
final DateTime kFirstCalendarDay = DateTime.utc(2004, 3, 9);
final DateTime kLastCalendarDay = DateTime.utc(DateTime.now().year + 8, 12, 31); // 8 years into the future

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
const int kDefaultCycleLength = 28;
const int kDefaultPeriodLength = 5;
const int kMinCycleLength = 7;
const int kMaxCycleLength = 90;
const int kMinPeriodLength = 1;
const int kMaxPeriodLength = 15;
const int kMinDaysBetweenPeriods = 2;

// Default user name
const String kMysteriousUserName = 'Mysterious User';

// Database constants
const String kDatabaseName = 'period_tracker.db';
const int kDatabaseVersion = 2;
const String kPeriodsTableName = 'periods';
const String kUserTableName = 'user';
const String kSettingsTableName = 'settings';
const String kNotificationsTableName = 'notifications';

// Notification constants
const String kNotificationChannelId = 'period_tracker_channel';
const String kNotificationChannelName = 'Period Tracker Notifications';
const String kNotificationChannelDescription = 'Notifications for Period Tracker';
const int kDefaultNotificationsDaysBefore = 3;
const int kMaxNotificationsDaysBefore = 14;
const int kDefaultNotificationHour = 8;

// Backup constants
const String kBackupFileName = 'period_tracker.json';
const String kBackupMimeType = 'application/json';
const String kBackupEmailTitle = 'Period Tracker Data';
const String kBackupEmailText =
    '''Attached is your $kBackupFileName file, which contains all your data. This file enables you to restore your data.

To restore your data on a new device:
1. Save the attached $kBackupFileName file on your new device.
2. Open the Files app and locate the file. By default, it should be in the Downloads folder.
3. Hold down on the file, click on the three dots and select Open with > Period Tracker.
4. In the Period Tracker app, click "Restore my data".''';

// Phone number constants
const String kDefaultIsoCountryCode = 'SI';
const String kDefaultCountryCode = '+386';

// Error codes
const String kRestoreErrorCode = "RESTORE_ERR";
const String kDogApiErrorCode = "DOG_ERR";
const String kNoEmailAppErrorCode = "NO_EMAIL_APP_ERR";
const String kUnknownErrorCode = "UNKNOWN_ERR";

// Emails
const String kFeedbackEmailSubject = 'Period Tracker Feedback';
const String kBugReportEmailSubject = 'Issue with Period Tracker';

// APIs
const String kDogApiBase = 'https://dog.ceo/api/breed';
const String kCatApiBase = 'https://api.thecatapi.com';

// Contact
const String kContactEmail = 'lanlebar6@gmail.com';
const String kKofiUrl = 'https://ko-fi.com/lebaaar';
const String kGitHubUrl = 'https://github.com/lebaaar/period_tracker';
const String kGooglePlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.lebaaar.period_tracker';
