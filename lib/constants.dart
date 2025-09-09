// UI
final double kBorderRadius = 12;
final double kTableCalendarDaysOfTheWeekHeight = 30;

// Date constants for calendar range
final DateTime kFirstCalendarDay = DateTime.utc(2020, 1, 1);
final DateTime kLastCalendarDay = DateTime.utc(DateTime.now().year + 8, 12, 31);

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
