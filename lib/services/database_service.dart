import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._constructor();

  factory DatabaseService() {
    return _instance;
  }

  final String _databaseName = 'period_tracker.db';
  final int _databaseVersion = 1;

  final String _periodsTableName = 'periods';
  final String _periodsIdColumnName = 'id';
  final String _periodsStartDateColumnName = 'startDate';
  final String _periodsEndDateColumnName = 'endDate';
  final String _periodsNotesColumnName = 'notes';

  final String _userTableName = 'user';
  final String _userIdColumnName = 'id';
  final String _userNameColumnName = 'name';
  final String _userCycleLengthColumnName = 'cycleLength';
  final String _userPeriodLengthColumnName = 'periodLength';
  final String _userLastPeriodDateColumnName = 'lastPeriodDate';
  final String _userDynamicCycleLength = 'dynamicCycleLength';

  final String _settingsTableName = 'settings';
  final String _settingsIdColumnName = 'id';
  final String _settingsPredictionModeColumnName = 'predictionMode';
  final String _settingsDarkModeColumnName = 'darkMode';
  final String _settingsNotificationEnabledColumnName = 'notificationEnabled';
  final String _settingsNotificationDaysBeforeColumnName =
      'notificationDaysBefore';
  final String _settingsNotificationTimeColumnName = 'notificationTime';

  final String _notificationTableName = 'notifications';
  final String _notificationIdColumnName = 'id';
  final String _notificationTitleColumnName = 'title';
  final String _notificationBodyColumnName = 'body';
  final String _notificationScheduledDateColumnName = 'scheduledDate';
  final String _notificationStatusColumnName = 'status';

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await getDatabase();
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = p.join(databaseDirPath, _databaseName);

    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    // periods table
    await db.execute('''
      CREATE TABLE $_periodsTableName (
        $_periodsIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_periodsStartDateColumnName TEXT NOT NULL,
        $_periodsEndDateColumnName TEXT,
        $_periodsNotesColumnName TEXT NULL
      )
    ''');

    // user table
    await db.execute('''
      CREATE TABLE $_userTableName (
        $_userIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_userNameColumnName TEXT NULL,
        $_userCycleLengthColumnName INTEGER NOT NULL,
        $_userPeriodLengthColumnName INTEGER NOT NULL,
        $_userLastPeriodDateColumnName TEXT NOT NULL,
        $_userDynamicCycleLength REAL NOT NULL DEFAULT 0
      )
    ''');

    // settings table
    await db.execute('''
      CREATE TABLE $_settingsTableName (
        $_settingsIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_settingsPredictionModeColumnName TEXT NOT NULL CHECK ($_settingsPredictionModeColumnName IN ('dynamic', 'static')) DEFAULT 'static',
        $_settingsDarkModeColumnName INTEGER NOT NULL DEFAULT 0,
        $_settingsNotificationEnabledColumnName INTEGER NOT NULL DEFAULT 0,
        $_settingsNotificationDaysBeforeColumnName INTEGER NOT NULL DEFAULT 3,
        $_settingsNotificationTimeColumnName TEXT NOT NULL DEFAULT '08:00'
      )
    ''');

    // notifications table
    await db.execute(
      '''
      CREATE TABLE $_notificationTableName (
        $_notificationIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_notificationTitleColumnName TEXT NOT NULL,
        $_notificationBodyColumnName TEXT NOT NULL,
        $_notificationScheduledDateColumnName TEXT NOT NULL,
        $_notificationStatusColumnName TEXT NOT NULL CHECK (status IN ('scheduled', 'sent', 'cancelled')) DEFAULT 'scheduled')''',
    );

    // insert default settings
    await db.insert(_settingsTableName, {
      _settingsIdColumnName: 1,
      _settingsPredictionModeColumnName: 'static',
      _settingsDarkModeColumnName: 1,
      _settingsNotificationEnabledColumnName: 0,
      _settingsNotificationDaysBeforeColumnName: 3,
      _settingsNotificationTimeColumnName: '08:00',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Period methods
  Future<List<Period>> getAllPeriods() async {
    final db = await database;
    final rows = await db.query(_periodsTableName);
    return rows.map((row) => Period.fromMap(row)).toList();
  }

  Future<int> insertPeriod(Period period) async {
    final db = await database;
    return await db.insert(
      _periodsTableName,
      period.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deletePeriod(int id) async {
    final db = await database;
    return await db.delete(
      _periodsTableName,
      where: '$_periodsIdColumnName = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePeriod(Period period) async {
    final db = await database;
    return await db.update(
      _periodsTableName,
      period.toMap(),
      where: '$_periodsIdColumnName = ?',
      whereArgs: [period.id],
    );
  }

  // User methods
  Future<User> getUser() async {
    final db = await database;
    final rows = await db.query(
      _userTableName,
      where: '$_userIdColumnName = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) {
      throw Exception('User with id=1 not found');
    }
    return User.fromMap(rows.first);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    final userMap = user.toMap()..['id'] = 1;
    return await db.insert(
      _userTableName,
      userMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Settings methods
  Future<Settings> getSettings() async {
    final db = await database;
    final rows = await db.query(
      _settingsTableName,
      where: '$_settingsIdColumnName = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) {
      throw Exception('Settings with id=1 not found');
    }
    return Settings.fromMap(rows.first);
  }

  Future<bool> getNotificationEnabled() async {
    final db = await database;
    final rows = await db.query(
      _settingsTableName,
      where: '$_settingsIdColumnName = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) return false;
    return rows.first[_settingsNotificationEnabledColumnName] == 1;
  }

  Future<void> updateNotificationEnabled(bool enabled) async {
    final db = await database;
    await db.update(
      _settingsTableName,
      {_settingsNotificationEnabledColumnName: enabled ? 1 : 0},
      where: '$_settingsIdColumnName = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateSettings(Settings settings) async {
    final db = await database;
    await db.update(
      _settingsTableName,
      {
        _settingsPredictionModeColumnName: settings.predictionMode,
        _settingsDarkModeColumnName: settings.darkMode ? 1 : 0,
        _settingsNotificationEnabledColumnName: settings.notificationEnabled
            ? 1
            : 0,
        _settingsNotificationDaysBeforeColumnName:
            settings.notificationDaysBefore,
        _settingsNotificationTimeColumnName:
            '${settings.notificationTime.hour.toString().padLeft(2, '0')}:${settings.notificationTime.minute.toString().padLeft(2, '0')}',
      },
      where: '$_settingsIdColumnName = ?',
      whereArgs: [1],
    );
  }
}
