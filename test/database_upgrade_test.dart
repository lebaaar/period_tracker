// Runs the real database, providers and backup/restore code on SQLite (ffi), seeded the way 1.3.2 left it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/backup_1_3_2.json').readAsStringSync())
        as Map<String, dynamic>;

late Directory _tmp;

String get _dbPath => '${_tmp.path}/$kDatabaseName';

/// The v2 schema exactly as 1.3.2 created it, filled with the fixture rows exactly as 1.3.2 wrote them.
Future<void> _seedLike132() async {
  final Map<String, dynamic> db =
      _fixture()['database'] as Map<String, dynamic>;
  final Database d = await openDatabase(
    _dbPath,
    version: 2,
    onCreate: (Database d, int _) async {
      await d.execute(
        'CREATE TABLE $kPeriodsTableName (id INTEGER PRIMARY KEY AUTOINCREMENT, startDate TEXT NOT NULL, endDate TEXT, notes TEXT NULL)',
      );
      await d.execute(
        'CREATE TABLE $kUserTableName (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NULL, cycleLength INTEGER NOT NULL, periodLength INTEGER NOT NULL, '
        "partnerPhoneNumber TEXT NULL, partnerMessageHeading TEXT NULL DEFAULT '$kDefaultPartnerMessageHeading')",
      );
      await d.execute(
        'CREATE TABLE $kSettingsTableName (id INTEGER PRIMARY KEY AUTOINCREMENT, '
        "predictionMode TEXT NOT NULL CHECK (predictionMode IN ('dynamic', 'static')) DEFAULT 'static', darkMode INTEGER NOT NULL DEFAULT 1, "
        "notificationEnabled INTEGER NOT NULL DEFAULT 1, notificationDaysBefore INTEGER NOT NULL DEFAULT 3, notificationTime TEXT NOT NULL DEFAULT '08:00')",
      );
    },
  );
  for (final Map<String, dynamic> p
      in (db['periods'] as List).cast<Map<String, dynamic>>()) {
    await d.insert(kPeriodsTableName, p);
  }
  await d.insert(kUserTableName, db['user'] as Map<String, dynamic>);
  await d.insert(kSettingsTableName, db['settings'] as Map<String, dynamic>);
  await d.close();
}

Future<({PeriodProvider periods, UserProvider user, SettingsProvider settings})>
_openProviders() async {
  final PeriodProvider p = PeriodProvider();
  final UserProvider u = UserProvider();
  final SettingsProvider s = SettingsProvider();
  await Future.wait([p.ready, u.ready, s.ready]);
  return (periods: p, user: u, settings: s);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    _tmp = await Directory.systemTemp.createTemp('pt_db_');
    await databaseFactory.setDatabasesPath(_tmp.path);
    await DatabaseService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Period Tracker',
      packageName: kPackageName,
      version: '2.0.0',
      buildNumber: '25',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async {
            final Directory d = Directory('${_tmp.path}/${call.method}')
              ..createSync(recursive: true);
            return d.path;
          },
        );
  });

  tearDown(() async {
    await DatabaseService.resetForTest();
    await _tmp.delete(recursive: true);
  });

  group('in-place update from 1.3.2 (same database, no migration)', () {
    test('all data is there', () async {
      await _seedLike132();
      final x = await _openProviders();

      expect(x.periods.periods, hasLength(14));
      expect(x.periods.periods.first.startDate, DateTime.utc(2026, 10, 4));
      expect(x.periods.periods.last.startDate, DateTime.utc(2025, 9, 22));
      expect(x.periods.periods.last.notes, 'example note');
      expect(x.user.user?.name, 'Test');
      expect(x.user.user?.cycleLength, 30);
      expect(x.user.user?.partnerPhoneNumber, 'SI|+386|00000000');
      expect(x.settings.settings?.notificationTime.hour, 9);
      expect(x.settings.settings?.notificationTime.minute, 3);
      expect(x.settings.settings?.predictionMode, 'dynamic');
      expect(x.periods.getNextPeriodDate(true, 30), DateTime.utc(2026, 11, 2));
    });

    test('edit, add and delete on old rows', () async {
      await _seedLike132();
      final x = await _openProviders();

      // edit an old period
      final Period old = x.periods.getPeriodById(14)!;
      await x.periods.updatePeriod(
        Period(
          id: old.id,
          startDate: DateTime(2026, 5, 11, 15),
          endDate: DateTime(2026, 5, 16, 9),
          notes: 'edited',
        ),
      );
      expect(x.periods.getPeriodById(14)!.startDate, DateTime.utc(2026, 5, 11));
      expect(x.periods.getPeriodById(14)!.notes, 'edited');

      // add a new one: it gets a real id right away and stays the newest
      await x.periods.insertPeriod(
        Period(
          startDate: DateTime(2026, 10, 29, 22, 15),
          endDate: DateTime(2026, 11, 2),
        ),
      );
      final Period added = x.periods.periods.first;
      expect(added.startDate, DateTime.utc(2026, 10, 29));
      expect(added.id, isNotNull);
      expect(added.id, greaterThan(19));

      // delete an old one, using the id the list gave us
      await x.periods.deletePeriod(6);
      expect(x.periods.getPeriodById(6), isNull);
      await x.periods.deletePeriod(added.id!);

      // a fresh load from disk agrees
      final PeriodProvider reloaded = PeriodProvider();
      await reloaded.ready;
      expect(reloaded.periods, hasLength(13));
      expect(reloaded.periods.map((p) => p.id).toSet(), hasLength(13));
      expect(reloaded.getPeriodById(14)!.startDate, DateTime.utc(2026, 5, 11));
      for (final Period p in reloaded.periods) {
        expect(
          p.startDate.isUtc && p.startDate.hour == 0 && p.startDate.minute == 0,
          isTrue,
        );
      }
    });

    test('changing user and settings keeps the rest', () async {
      await _seedLike132();
      final x = await _openProviders();
      await x.user.updateUser(cycleLength: 28, periodLength: 6, name: 'Test');
      await x.settings.setPredictionMode('static');
      await x.settings.setNotificationEnabled(false);
      await x.settings.updateSettings(notificationDaysBefore: 5);

      await DatabaseService.resetForTest();
      final y = await _openProviders();
      expect(y.user.user?.cycleLength, 28);
      expect(y.user.user?.periodLength, 6);
      expect(y.user.user?.partnerPhoneNumber, 'SI|+386|00000000');
      expect(y.settings.settings?.predictionMode, 'static');
      expect(y.settings.settings?.notificationsEnabled, isFalse);
      expect(y.settings.settings?.notificationDaysBefore, 5);
      expect(y.settings.settings?.notificationTime.hour, 9);
      expect(y.periods.periods, hasLength(14));
    });
  });

  group('restore', () {
    test('a 1.3.2 backup replaces existing data', () async {
      await _seedLike132();
      // current device has different data and other prefs
      final x = await _openProviders();
      await x.periods.deletePeriod(19);
      await x.user.updateUser(
        cycleLength: 21,
        periodLength: 3,
        name: 'Someone else',
      );
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': false,
        'unrelated': 'x',
      });

      final ApplicationDataService service = ApplicationDataService();
      expect(await service.restoreFromBackup(_fixture()), isTrue);

      final y = await _openProviders();
      expect(y.periods.periods, hasLength(14));
      expect(y.periods.periods.first.startDate, DateTime.utc(2026, 10, 4));
      expect(y.user.user?.name, 'Test');
      expect(y.user.user?.cycleLength, 30);
      expect(y.settings.settings?.notificationTime.minute, 3);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(prefs.getBool('animal_generator_unlocked'), isTrue);
      expect(prefs.getBool('display_version_details'), isTrue);
      expect(prefs.containsKey('unrelated'), isFalse);
    });

    test('restore on a brand new install', () async {
      final ApplicationDataService service = ApplicationDataService();
      expect(await service.restoreFromBackup(_fixture()), isTrue);
      final y = await _openProviders();
      expect(y.periods.periods, hasLength(14));
      expect(y.user.user?.name, 'Test');
    });

    test(
      'backup without a user or without preferences still restores',
      () async {
        final ApplicationDataService service = ApplicationDataService();
        final Map<String, dynamic> noUser = _fixture();
        (noUser['database'] as Map<String, dynamic>)['user'] = null;
        expect(service.isBackupDataValid(noUser), isTrue);
        expect(await service.restoreFromBackup(noUser), isTrue);
        expect((await _openProviders()).periods.periods, hasLength(14));

        final Map<String, dynamic> noPrefs = _fixture()
          ..['sharedPreferences'] = null;
        await DatabaseService.resetForTest();
        expect(await service.restoreFromBackup(noPrefs), isTrue);
      },
    );

    test(
      'a backup made by the current version round-trips (incl. theme)',
      () async {
        await _seedLike132();
        SharedPreferences.setMockInitialValues({
          'onboarding_complete': true,
          'theme_mode': 'dark',
          'animal_generator_unlocked': true,
        });
        final ApplicationDataService service = ApplicationDataService();

        final String content = await service.createBackupFileContent();
        final Map<String, dynamic> parsed = service.parseBackupFile(content);
        expect(service.isJsonFromPeriodTracker(parsed), isTrue);
        expect(service.isBackupDataValid(parsed), isTrue);
        expect(
          service.verifyVersionCompatibility(
            parsed['databaseVersion'] as int,
            kDatabaseVersion,
          ),
          isTrue,
        );
        expect(parsed['version'], '2.0.0');

        // wipe, restore, compare
        await service.clearAppData();
        expect((await _openProviders()).periods.periods, isEmpty);
        expect(await service.restoreFromBackup(parsed), isTrue);

        final y = await _openProviders();
        expect(y.periods.periods, hasLength(14));
        expect(
          y.periods.periods.map((p) => p.startDate.toIso8601String()).first,
          '2026-10-04T00:00:00.000Z',
        );
        expect(y.user.user?.name, 'Test');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'dark');
        expect(prefs.getBool('onboarding_complete'), isTrue);
      },
    );

    test('delete account wipes everything', () async {
      await _seedLike132();
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      await ApplicationDataService().clearAppData();
      final y = await _openProviders();
      expect(y.periods.periods, isEmpty);
      expect(y.user.user, isNull);
      expect(y.settings.settings, isNotNull); // default settings are recreated
      expect(
        (await SharedPreferences.getInstance()).getBool('onboarding_complete'),
        isFalse,
      );
    });
  });

  group('v1 -> v2 migration', () {
    Future<void> seedV1() async {
      final Database d = await openDatabase(
        _dbPath,
        version: 1,
        onCreate: (Database d, int _) async {
          await d.execute(
            'CREATE TABLE $kPeriodsTableName (id INTEGER PRIMARY KEY AUTOINCREMENT, startDate TEXT NOT NULL, endDate TEXT, notes TEXT NULL)',
          );
          await d.execute(
            'CREATE TABLE $kUserTableName (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NULL, cycleLength INTEGER NOT NULL, periodLength INTEGER NOT NULL, '
            'lastPeriodDate TEXT NOT NULL, dynamicCycleLength REAL NOT NULL DEFAULT 0)',
          );
          await d.execute(
            'CREATE TABLE $kSettingsTableName (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            "predictionMode TEXT NOT NULL CHECK (predictionMode IN ('dynamic', 'static')) DEFAULT 'static', darkMode INTEGER NOT NULL DEFAULT 1, "
            "notificationEnabled INTEGER NOT NULL DEFAULT 1, notificationDaysBefore INTEGER NOT NULL DEFAULT 3, notificationTime TEXT NOT NULL DEFAULT '08:00')",
          );
        },
      );
      await d.insert(kPeriodsTableName, {
        'startDate': '2026-09-07T00:00:00.000Z',
        'endDate': '2026-09-11T00:00:00.000Z',
        'notes': 'old',
      });
      await d.insert(kUserTableName, {
        'id': 1,
        'name': 'Old user',
        'cycleLength': 29,
        'periodLength': 4,
        'lastPeriodDate': '2026-09-07T00:00:00.000Z',
        'dynamicCycleLength': 28.5,
      });
      await d.insert(kSettingsTableName, {
        'id': 1,
        'predictionMode': 'static',
        'darkMode': 1,
        'notificationEnabled': 1,
        'notificationDaysBefore': 2,
        'notificationTime': '08:00',
      });
      await d.close();
    }

    test('keeps data and the user can be saved afterwards', () async {
      await seedV1();
      final x = await _openProviders();
      expect(x.periods.periods.single.notes, 'old');
      expect(x.user.user?.name, 'Old user');
      expect(x.user.user?.cycleLength, 29);
      expect(x.user.user?.periodLength, 4);
      expect(x.user.user?.partnerMessageHeading, kDefaultPartnerMessageHeading);
      expect(x.settings.settings?.notificationDaysBefore, 2);

      // would throw "NOT NULL constraint failed: lastPeriodDate" if the old column were left behind
      await x.user.updateUser(
        cycleLength: 31,
        periodLength: 5,
        name: 'Old user',
        partnerPhoneNumber: 'SI|+386|11111111',
      );
      await DatabaseService.resetForTest();
      final User? u = (await _openProviders()).user.user;
      expect(u?.cycleLength, 31);
      expect(u?.partnerPhoneNumber, 'SI|+386|11111111');

      final Database raw = await databaseFactory.openDatabase(_dbPath);
      final List<String> cols = (await raw.rawQuery(
        'PRAGMA table_info($kUserTableName)',
      )).map((r) => r['name'] as String).toList();
      await raw.close();
      expect(cols, [
        'id',
        'name',
        'cycleLength',
        'periodLength',
        'partnerPhoneNumber',
        'partnerMessageHeading',
      ]);
    });
  });

  test('fresh install creates default settings and no user', () async {
    final x = await _openProviders();
    expect(x.user.user, isNull);
    expect(x.settings.settings?.predictionMode, 'dynamic');
    expect(x.settings.settings?.notificationTime.hour, 8);
    expect(x.periods.periods, isEmpty);
  });
}
