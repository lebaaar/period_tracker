// Renders the real app screens with seeded data for the Play Store graphics.
// Run: flutter test test/shots_test.dart   (writes graphics/play/shots/*.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/pages/home_page.dart';
import 'package:period_tracker/pages/insights_page.dart';
import 'package:period_tracker/pages/log_period_page.dart';
import 'package:period_tracker/pages/onboarding_screen.dart';
import 'package:period_tracker/pages/profile_page.dart';
import 'package:period_tracker/pages/restore_help_page.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/theme_provider.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/bottom_tab_bar.dart';
import 'package:provider/provider.dart';

class _Periods extends PeriodProvider {
  static bool hideLatest = false; // drop the current period (log screen shows an empty slate)
  @override
  Future<void> fetchPeriods() async {
    final DateTime t = DateTime.now();
    final DateTime today = DateTime(t.year, t.month, t.day);
    // newest first; cycle lengths 28,27,29,28,30,28 ; period 5,4,5,5,6,5 days
    final List<int> gaps = [8, 36, 64, 93, 121, 151, 179]; // days ago of each start
    final List<int> lens = [5, 5, 4, 5, 5, 6, 5];
    _seed(today, gaps, lens);
    _loaded2 = true;
    notifyListeners();
  }

  bool _loaded2 = false;
  @override
  bool get isLoaded => _loaded2;

  void _seed(DateTime today, List<int> gaps, List<int> lens) {
    periods.clear();
    for (int i = hideLatest ? 1 : 0; i < gaps.length; i++) {
      final DateTime s = today.subtract(Duration(days: gaps[i]));
      periods.add(Period(id: i + 1, startDate: s, endDate: s.add(Duration(days: lens[i] - 1))));
    }
  }
}

class _User extends UserProvider {
  @override
  Future<void> fetchUser() async {}
  @override
  User? get user => User(id: 1, name: 'Nina', cycleLength: 28, periodLength: 5);
}

class _Settings extends SettingsProvider {
  @override
  Future<void> loadSettings() async {}
  @override
  Settings? get settings => Settings(
    id: 1,
    predictionMode: 'dynamic',
    darkMode: false,
    notificationsEnabled: true,
    notificationDaysBefore: 2,
    notificationTime: const TimeOfDay(hour: 9, minute: 0),
  );
}

Widget _status(bool dark) {
  final Color c = dark ? Colors.white : Colors.black;
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: 52,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 28, 0),
      child: Row(
        children: [
          Text('9:41', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: c)),
          const Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, size: 17, color: c),
          const SizedBox(width: 6),
          Icon(Icons.wifi_rounded, size: 17, color: c),
          const SizedBox(width: 6),
          Icon(Icons.battery_full_rounded, size: 19, color: c),
        ],
      ),
    ),
  );
}

Future<void> _shoot(WidgetTester tester, String name, Widget page, {int tab = -1, bool dark = false, double scroll = 0, double height = 2532, bool openTransfer = false, bool hideLatest = false}) async {
  _Periods.hideLatest = hideLatest;
  tester.view.physicalSize = Size(1170, height);
  final GlobalKey key = GlobalKey();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PeriodProvider>.value(value: _Periods()),
        ChangeNotifierProvider<UserProvider>.value(value: _User()),
        ChangeNotifierProvider<SettingsProvider>.value(value: _Settings()),
        ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider(dark ? ThemeMode.dark : ThemeMode.light)),
        ChangeNotifierProvider<UnlocksProvider>.value(value: UnlocksProvider(false, false)),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: context.colors.background,
              extendBody: true,
              body: Stack(
                children: [
                  Positioned.fill(child: page),
                  _status(dark),
                ],
              ),
              bottomNavigationBar: tab < 0
                  ? null
                  : BottomTabBar(
                      index: tab,
                      onChanged: (_) {},
                      items: const [
                        BottomTabItem(label: 'Today', icon: Icons.today_outlined, selectedIcon: Icons.today_rounded),
                        BottomTabItem(label: 'Insights', icon: Icons.show_chart_rounded, selectedIcon: Icons.show_chart_rounded),
                        BottomTabItem(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded),
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  for (int i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (scroll > 0) {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  if (openTransfer) {
    await tester.scrollUntilVisible(find.text('Transfer data'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Transfer data'));
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  await tester.runAsync(() async {
    final RenderRepaintBoundary b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('graphics/play/shots/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _loadFonts() async {
  final FontLoader inter = FontLoader('Inter');
  for (final String w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(Future.value(ByteData.view(File('assets/fonts/Inter-$w.ttf').readAsBytesSync().buffer)));
  }
  await inter.load();
  final FontLoader icons = FontLoader('MaterialIcons');
  icons.addFont(Future.value(ByteData.view(File('/home/lebar/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);
  for (final bool dark in [false, true]) {
    final String s = dark ? '_dark' : '';
    testWidgets('shots$s', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 52 * 3, bottom: 20 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 52 * 3, bottom: 20 * 3);
      addTearDown(tester.view.reset);
      await _shoot(tester, 'home$s', const HomePage(), tab: 0, dark: dark);
      await _shoot(tester, 'insights$s', const InsightsPage(), tab: 1, dark: dark);
      await _shoot(tester, 'settings$s', const ProfilePage(), tab: 2, dark: dark);
      await _shoot(tester, 'restore$s', const RestoreHelpPage(initialTab: 'restore'), dark: dark);
      await _shoot(tester, 'settings2$s', const ProfilePage(), tab: 2, dark: dark, scroll: 560);
      await _shoot(tester, 'reminders$s', const ProfilePage(), tab: 2, dark: dark, scroll: 410);
      await _shoot(tester, 'transfer$s', const ProfilePage(), tab: 2, dark: dark, height: 1884, openTransfer: true);
      await _shoot(tester, 'log$s', LogPeriodPage(isEditing: false, period: null, focusedDay: DateTime.now()), dark: dark, hideLatest: true);
      await _shoot(tester, 'onboarding$s', const OnboardingScreen(), dark: dark);
    });
  }
}
