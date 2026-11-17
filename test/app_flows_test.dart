// Drives the real app (router, pages, providers, database) the way a user would,
// seeded with the anonymised 1.3.2 backup and a fixed "today" of 2026-10-30.
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/main.dart';
import 'package:period_tracker/pages/log_period_page.dart';
import 'package:period_tracker/pages/restore_data_preview_page.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/theme_provider.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/database_service.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final DateTime _today = DateTime(2026, 10, 30, 12);
final Clock _fixedClock = Clock.fixed(_today);

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/backup_1_3_2.json').readAsStringSync())
        as Map<String, dynamic>;

class _Calls {
  final List<MethodCall> notifications = [];
  final List<MethodCall> share = [];
  final List<MethodCall> restart = [];
  List<MethodCall> scheduled() =>
      notifications.where((c) => c.method == 'zonedSchedule').toList();
}

class _App {
  final PeriodProvider periods;
  final UserProvider user;
  final SettingsProvider settings;
  final ThemeProvider theme;
  final UnlocksProvider unlocks;
  final _Calls calls;
  _App(
    this.periods,
    this.user,
    this.settings,
    this.theme,
    this.unlocks,
    this.calls,
  );
}

late Directory _tmp;

Future<void> _seed132() async {
  final Map<String, dynamic> db =
      _fixture()['database'] as Map<String, dynamic>;
  final Database d = await openDatabase(
    '${_tmp.path}/$kDatabaseName',
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

void _mockChannels(_Calls calls) {
  final TestDefaultBinaryMessengerBinding b =
      TestDefaultBinaryMessengerBinding.instance;
  void mock(String name, Future<Object?>? Function(MethodCall) h) =>
      b.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(name), h);

  mock('plugins.flutter.io/path_provider', (c) async {
    final Directory d = Directory('${_tmp.path}/${c.method}')
      ..createSync(recursive: true);
    return d.path;
  });
  mock(
    'receive_sharing_intent/messages',
    (c) async => c.method == 'getInitialMedia' ? '[]' : null,
  );
  b.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('receive_sharing_intent/events-media'),
    MockStreamHandler.inline(onListen: (_, _) {}),
  );
  mock('dexterous.com/flutter/local_notifications', (c) async {
    calls.notifications.add(c);
    switch (c.method) {
      case 'initialize':
      case 'canScheduleExactNotifications':
      case 'requestNotificationsPermission':
      case 'requestExactAlarmsPermission':
        return true;
      case 'pendingNotificationRequests':
        return <Map<String, Object?>>[];
    }
    return null;
  });
  mock(
    'flutter_timezone',
    (c) async => throw PlatformException(code: 'unavailable'),
  ); // falls back to Europe/Ljubljana
  mock(
    'de.ffuf.in_app_update/methods',
    (c) async => throw PlatformException(code: 'unavailable'),
  );
  mock('dev.fluttercommunity.plus/share', (c) async {
    calls.share.add(c);
    return 'success';
  });
  mock('restart', (c) async {
    calls.restart.add(c);
    return true;
  });
}

/// Starts the app like `main()` does and returns the providers it uses.
Future<_App> _launch(
  WidgetTester tester, {
  bool seeded = true,
  bool onboarded = true,
  Map<String, Object> prefs = const {},
}) async {
  AndroidFlutterLocalNotificationsPlugin.registerWith(); // on a real phone the plugin registrant does this

  final _Calls calls = _Calls();
  _mockChannels(calls);
  PackageInfo.setMockInitialValues(
    appName: 'Period Tracker',
    packageName: kPackageName,
    version: '2.0.0',
    buildNumber: '25',
    buildSignature: '',
  );
  SharedPreferences.setMockInitialValues({
    if (onboarded) 'onboarding_complete': true,
    if (seeded) ...{
      'animal_generator_unlocked': true,
      'display_version_details': true,
    },
    ...prefs,
  });
  await tester.runAsync(NotificationService().init); // as main() does
  if (seeded) await tester.runAsync(_seed132);

  late final PeriodProvider periods;
  late final UserProvider user;
  late final SettingsProvider settings;
  late final ThemeProvider theme;
  late final UnlocksProvider unlocks;
  await tester.runAsync(() async {
    theme = await ThemeProvider.load();
    unlocks = await UnlocksProvider.load();
    periods = PeriodProvider();
    user = UserProvider();
    settings = SettingsProvider();
    await Future.wait([periods.ready, user.ready, settings.ready]);
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: periods),
        ChangeNotifierProvider.value(value: user),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: unlocks),
      ],
      child: PeriodTrackerApp(
        showOnboarding: !onboarded,
        isAfterRestore: false,
      ),
    ),
  );
  await _settle(tester);
  return _App(periods, user, settings, theme, unlocks, calls);
}

/// Lets queued database/file work and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

/// The page's vertical scroll view (not the calendar's horizontal pager).
Finder _vertical() => find
    .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
    .hitTestable();

Future<void> _tap(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    // lazy lists only build what is on screen, so scroll the page that is showing
    for (final Element e in _vertical().evaluate().toList()) {
      if (f.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(
          f,
          250,
          scrollable: find.byElementPredicate((x) => x == e),
          maxScrolls: 12,
        );
      } catch (_) {}
    }
  }
  if (f.evaluate().isEmpty) {
    final String texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .join(' | ');
    fail('Nothing found for $f. Visible texts: $texts');
  }
  // ensureVisible always scrolls the target to the top edge, which pushes its neighbours off screen
  if (f.hitTestable().evaluate().isEmpty) await tester.ensureVisible(f.first);
  await tester.tap(f.first, warnIfMissed: true);
  await _settle(tester);
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> _go(WidgetTester tester, String location) async {
  _router(tester).go(location);
  await _settle(tester);
}

String _iso(DateTime d) => Uri.encodeComponent(d.toIso8601String());

/// A test on a phone-sized Android screen with today fixed to 2026-10-30.
void _flow(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    tester.view.physicalSize = const Size(
      1080,
      4800,
    ); // tall phone: every row fits, no scrolling under the tab bar
    tester.view.devicePixelRatio = 3;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await withClock(_fixedClock, () => body(tester));
    } finally {
      debugDefaultTargetPlatformOverride =
          null; // must be unset before the test ends
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}

void main() {
  setUpAll(() async {
    // the app's own font, so text is measured like on a phone (the test default makes every letter a wide square)
    final FontLoader inter = FontLoader('Inter');
    for (final String w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(
        Future.value(
          ByteData.view(
            File('assets/fonts/Inter-$w.ttf').readAsBytesSync().buffer,
          ),
        ),
      );
    }
    await inter.load();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    _tmp = await Directory.systemTemp.createTemp('pt_flow_');
    await databaseFactory.setDatabasesPath(_tmp.path);
    await DatabaseService.resetForTest();
  });

  tearDown(() async {
    await DatabaseService.resetForTest();
    await _tmp.delete(recursive: true);
  });

  _flow('Today screen shows the 1.3.2 data and the right prediction', (
    tester,
  ) async {
    await _launch(tester);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Period in 3 days'), findsOneWidget);
    expect(find.text('Next period Mon, 2 Nov'), findsOneWidget);
    expect(find.text('27'), findsWidgets); // cycle day in the ring
    expect(find.text('Cycle day 27'), findsOneWidget);
    expect(
      find.text('Order boyfriend'),
      findsOneWidget,
    ); // both unlocks restored from 1.3.2
  });

  _flow('log a new period from Today', (tester) async {
    final _App app = await _launch(tester);
    await _tap(tester, find.text('Log')); // selected day is today
    expect(find.text('Log period'), findsWidgets);
    expect(
      find.text('30 Oct – 3 Nov'),
      findsOneWidget,
    ); // default range = usual period length (5 days)

    app.calls.notifications.clear();
    await _tap(tester, find.text('Save'));

    expect(app.periods.periods, hasLength(15));
    expect(app.periods.periods.first.startDate, DateTime.utc(2026, 10, 30));
    expect(app.periods.periods.first.endDate, DateTime.utc(2026, 11, 3));
    expect(app.periods.periods.first.id, isNotNull);
    expect(find.text('Day 1 of your period'), findsOneWidget);
    // dynamic: last 6 starts 06-10 .. 10-30 -> gaps 31 29 29 27 26 -> 28.4 -> 28 days -> 27 Nov
    expect(find.text('Next period Fri, 27 Nov'), findsOneWidget);

    // reminders were rescheduled for 24..27 Nov at 09:03 (id 3..0)
    final List<MethodCall> scheduled = app.calls.scheduled();
    expect(scheduled, hasLength(4));
    expect(scheduled.map((c) => (c.arguments as Map)['id']).toList()..sort(), [
      0,
      1,
      2,
      3,
    ]);
  });

  _flow('bad ranges are refused with a message', (tester) async {
    final _App app = await _launch(tester);

    Future<void> tryLogAt(DateTime day, String message) async {
      await _go(tester, '/log?isEditing=false&focusedDay=${_iso(day)}');
      await _tap(tester, find.text('Save'));
      expect(find.text(message), findsOneWidget, reason: 'for $day');
      expect(app.periods.periods, hasLength(14));
      await _go(tester, '/');
    }

    await tryLogAt(
      DateTime.utc(2026, 10, 6),
      'The selected period overlaps with an existing one',
    ); // inside 4-8 Oct
    await tryLogAt(
      DateTime.utc(2026, 10, 9),
      'There must be at least 2 days between periods',
    ); // day after 8 Oct
    await tryLogAt(
      DateTime.utc(2026, 11, 5),
      'The start date cannot be in the future.',
    );
  });

  _flow('edit an old period: notes and dates', (tester) async {
    final _App app = await _launch(tester);
    await _go(
      tester,
      '/log?isEditing=true&periodId=19&focusedDay=${_iso(DateTime.utc(2026, 10, 4))}',
    );
    expect(find.text('Edit period'), findsOneWidget);
    expect(find.text('4 Oct – 8 Oct'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'felt fine');
    await _tap(tester, find.text('Save'));

    expect(app.periods.getPeriodById(19)!.notes, 'felt fine');
    expect(app.periods.getPeriodById(19)!.startDate, DateTime.utc(2026, 10, 4));
    expect(app.periods.periods, hasLength(14));

    // change the dates by picking a new range on the calendar
    await _go(
      tester,
      '/log?isEditing=true&periodId=19&focusedDay=${_iso(DateTime.utc(2026, 10, 4))}',
    );
    await _tap(
      tester,
      find.descendant(of: find.byType(LogPeriodPage), matching: find.text('5')),
    );
    await _tap(
      tester,
      find.descendant(of: find.byType(LogPeriodPage), matching: find.text('9')),
    );
    await _tap(tester, find.text('Save'));
    expect(app.periods.getPeriodById(19)!.startDate, DateTime.utc(2026, 10, 5));
    expect(app.periods.getPeriodById(19)!.endDate, DateTime.utc(2026, 10, 9));
    expect(app.periods.getPeriodById(19)!.notes, 'felt fine');
  });

  _flow('delete a period', (tester) async {
    final _App app = await _launch(tester);
    await _go(
      tester,
      '/log?isEditing=true&periodId=19&focusedDay=${_iso(DateTime.utc(2026, 10, 4))}',
    );
    await _tap(tester, find.text('Delete period'));
    await _tap(tester, find.text('Delete'));

    expect(app.periods.periods, hasLength(13));
    expect(app.periods.getPeriodById(19), isNull);
    // last start is now 09-07, so the next one is 09-07 + average(…) and Today still renders
    expect(find.text('Today'), findsWidgets);
    expect(
      find.textContaining('late'),
      findsOneWidget,
    ); // predicted early October, so it is overdue
  });

  _flow('insights show averages, sorting and history', (tester) async {
    await _launch(tester);
    await _tap(tester, find.text('Insights'));
    expect(find.text('Average cycle'), findsOneWidget);
    expect(find.text('29.0'), findsOneWidget);
    expect(find.text('Average period'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    await _tap(tester, find.text('All time'));
    expect(find.text('29.0'), findsOneWidget);
    await _tap(tester, find.text('Last 6'));
    expect(find.text('29.0'), findsOneWidget);
  });

  _flow('settings: predictions, reminders, theme', (tester) async {
    final _App app = await _launch(tester);
    await _tap(tester, find.text('Settings'));
    expect(find.text('Nina'), findsNothing); // anonymised fixture
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('9:03'), findsOneWidget); // "9:3" from 1.3.2, shown padded
    expect(find.text('30 days'), findsOneWidget);

    // switch to fixed cycle length
    await _tap(tester, find.text('Smart predictions'));
    await _tap(tester, find.text('Switch'));
    expect(app.settings.settings!.predictionMode, 'static');
    // static: last start 04 Oct + 30 days = 03 Nov, reminders at 09:03 on 31 Oct..3 Nov
    expect(app.calls.scheduled().length, greaterThanOrEqualTo(4));

    // reminders off then on
    app.calls.notifications.clear();
    await _tap(tester, find.text('Period reminders'));
    expect(app.settings.settings!.notificationsEnabled, isFalse);
    expect(app.calls.notifications.any((c) => c.method == 'cancelAll'), isTrue);
    expect(app.calls.scheduled(), isEmpty);
    await _tap(tester, find.text('Period reminders'));
    expect(app.settings.settings!.notificationsEnabled, isTrue);
    expect(app.calls.scheduled(), hasLength(4));

    // theme
    await _tap(tester, find.text('Dark'));
    expect(app.theme.mode, ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getString('theme_mode'),
      'dark',
    );
  });

  _flow('reminder time uses the Material time picker', (tester) async {
    final _App app = await _launch(tester);
    await _tap(tester, find.text('Settings'));
    await _tap(tester, find.text('9:03'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    app.calls.notifications.clear();
    await _tap(tester, find.text('OK'));
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(app.settings.settings!.notificationTime, const TimeOfDay(hour: 9, minute: 3));
    expect(app.calls.scheduled(), isNotEmpty);
  });

  _flow('export backup from Settings', (tester) async {
    final _App app = await _launch(tester);
    await _tap(tester, find.text('Settings'));
    await _tap(tester, find.text('Transfer data'));
    await _tap(tester, find.text('Send backup file'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await _settle(tester);
    expect(app.calls.share, hasLength(1));
    expect(find.text('Backup file sent successfully'), findsOneWidget);
    final File sent = File(
      '${_tmp.path}/getTemporaryDirectory/$kBackupFileName',
    );
    final Map<String, dynamic> content =
        jsonDecode(sent.readAsStringSync()) as Map<String, dynamic>;
    expect(content['app'], kPackageName);
    expect((content['database'] as Map)['periods'] as List, hasLength(14));
  });

  _flow('delete account then onboarding starts', (tester) async {
    final _App app = await _launch(tester);
    await _tap(tester, find.text('Settings'));
    await _tap(tester, find.text('Delete account'));
    await _tap(tester, find.text('Continue'));
    await _tap(tester, find.text('I understand'));
    await _tap(tester, find.text('Delete everything'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await _settle(tester);

    expect(find.text('Account deleted successfully'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('onboarding_complete'),
      isFalse,
    );
    await tester.runAsync(() async {
      await app.periods.fetchPeriods();
      await app.user.fetchUser();
    });
    expect(app.periods.periods, isEmpty);
    expect(app.user.user, isNull);
  });

  _flow('onboarding on a fresh install creates the account', (tester) async {
    final _App app = await _launch(tester, seeded: false, onboarded: false);
    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Mia');
    await _tap(tester, find.text('Continue')); // -> lengths
    await _tap(tester, find.text('Continue')); // -> last period
    await _tap(
      tester,
      find.text('Get started').first.evaluate().isEmpty
          ? find.text('Continue')
          : find.text('Get started'),
    ).catchError((_) {});
    expect(find.text('No day selected yet'), findsOneWidget);
    await _tap(tester, find.text('20')); // 20 Oct
    expect(find.text('Started 20 October 2026'), findsOneWidget);
    await _tap(tester, find.text('Get started'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await _settle(tester);

    expect(app.user.user?.name, 'Mia');
    expect(app.user.user?.cycleLength, 28);
    expect(app.periods.periods.single.startDate, DateTime.utc(2026, 10, 20));
    expect(app.periods.periods.single.endDate, DateTime.utc(2026, 10, 24));
    expect(app.settings.settings, isNotNull);
    expect(
      (await SharedPreferences.getInstance()).getBool('onboarding_complete'),
      isTrue,
    );
    expect(find.text('Today'), findsWidgets);
    expect(
      find.text('Next period Tue, 17 Nov'),
      findsOneWidget,
    ); // 20 Oct + 28 days
    expect(app.calls.scheduled(), isNotEmpty);
  });

  Future<void> openRestorePreview(WidgetTester tester, _App app) async {
    final File shared = File('${_tmp.path}/shared/$kBackupFileName')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(_fixture()));
    final GoRouter router = GoRouter(
      initialLocation: '/restore',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const Scaffold(body: Text('ONBOARDING')),
        ),
        GoRoute(
          path: '/restore',
          builder: (_, _) =>
              RestoreDataPreviewPage(sharedFiles: [_SharedFile(shared.path)]),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app.periods),
          ChangeNotifierProvider.value(value: app.user),
          ChangeNotifierProvider.value(value: app.settings),
          ChangeNotifierProvider.value(value: app.theme),
          ChangeNotifierProvider.value(value: app.unlocks),
        ],
        child: MaterialApp.router(theme: lightTheme, routerConfig: router),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _settle(tester);
  }

  _flow('restore a 1.3.2 backup on a new install', (tester) async {
    final _App app = await _launch(tester, seeded: false, onboarded: false);
    await openRestorePreview(tester, app);
    expect(find.text('Welcome back, Test!'), findsOneWidget);
    expect(find.textContaining('including 14 logged periods'), findsOneWidget);

    app.calls.notifications.clear();
    await tester.tap(find.text('Restore my data'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(
      const Duration(seconds: 3),
    ); // the page shows its spinner for 2 s
    await _settle(tester);

    expect(
      app.calls.restart,
      hasLength(1),
    ); // app restarts into the restored data
    expect(app.periods.periods, hasLength(14));
    expect(app.user.user?.name, 'Test');
    expect(
      app.settings.settings?.notificationTime,
      const TimeOfDay(hour: 9, minute: 3),
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(
      prefs.getBool('display_restore_success'),
      isTrue,
    ); // shows "Data restored successfully" after the restart
    // reminders for the restored prediction (2 Nov): the one for 30 Oct 09:03 is already in the past at 12:00
    expect(app.calls.scheduled().map((c) => (c.arguments as Map)['id']).toList()..sort(), [0, 1, 2]);
  });

  _flow('restore over an existing account asks first', (tester) async {
    final _App app = await _launch(
      tester,
    ); // already has the same data, so change something first
    await tester.runAsync(() => app.periods.deletePeriod(19));
    await openRestorePreview(tester, app);
    expect(find.text('Replace your current data?'), findsOneWidget);
    await _tap(tester, find.text('Continue'));
    expect(find.text('Welcome, Test!'), findsOneWidget);

    await tester.tap(find.text('Restore my data'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    expect(app.periods.periods, hasLength(14)); // the deleted period is back
    expect(app.calls.restart, hasLength(1));
  });
}

class _SharedFile {
  final String path;
  _SharedFile(this.path);
}
