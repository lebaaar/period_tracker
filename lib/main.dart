import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/pages/about_page.dart';
import 'package:period_tracker/pages/animal_generator_page.dart';
import 'package:period_tracker/pages/notifications_page.dart';
import 'package:period_tracker/pages/onboarding_restore_data_page.dart';
import 'package:period_tracker/pages/onboarding_screen.dart';
import 'package:period_tracker/pages/restore_data_preview_page.dart';
import 'package:period_tracker/pages/restore_help_page.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/theme_provider.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/bottom_tab_bar.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'pages/home_page.dart';
import 'pages/insights_page.dart';
import 'pages/log_period_page.dart';
import 'pages/profile_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  final ThemeProvider themeProvider = await ThemeProvider.load();
  final UnlocksProvider unlocksProvider = await UnlocksProvider.load();
  final bool onBoardingComplete = await getOnboardingComplete();
  final bool isAfterRestore = await getDisplayRestoreSuccess();
  if (isAfterRestore) {
    await clearDisplayRestoreSuccess();
  }

  // Load before the first frame so pages never flash their empty state.
  final PeriodProvider periodProvider = PeriodProvider();
  final UserProvider userProvider = UserProvider();
  final SettingsProvider settingsProvider = SettingsProvider();
  await Future.wait([periodProvider.ready, userProvider.ready, settingsProvider.ready].map((f) => f.catchError((Object _) {})));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: periodProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: unlocksProvider),
      ],
      child: PeriodTrackerApp(showOnboarding: !onBoardingComplete, isAfterRestore: isAfterRestore),
    ),
  );
}

class PeriodTrackerApp extends StatefulWidget {
  final bool showOnboarding;
  final bool isAfterRestore;
  const PeriodTrackerApp({super.key, required this.showOnboarding, required this.isAfterRestore});

  @override
  State<PeriodTrackerApp> createState() => _PeriodTrackerAppState();
}

class _PeriodTrackerAppState extends State<PeriodTrackerApp> {
  late StreamSubscription _intentSub;
  final List _sharedFiles = [];
  late final GoRouter _router = _buildRouter();

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        setState(() {
          _sharedFiles.clear();
          _sharedFiles.addAll(value);
          if (_sharedFiles.isNotEmpty) {
            _setFileShared(true);
          }
        });
      },
      onError: (err) {
        // TODO: handle error
      },
    );

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        if (_sharedFiles.isNotEmpty) {
          _setFileShared(true);
        }

        ReceiveSharingIntent.instance.reset();
      });
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  Future<void> _setFileShared(bool value) async {
    await setFileShared(value);
  }

  // built once: recreating it on rebuild (e.g. theme change) resets navigation to home
  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: widget.showOnboarding ? '/onboarding' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MainNavigation(isAfterRestore: widget.isAfterRestore),
          routes: [
            GoRoute(
              path: 'log',
              builder: (context, state) {
                final bool isEditing = state.uri.queryParameters['isEditing'] == 'true';
                final String? periodId = state.uri.queryParameters['periodId'];
                final Period? period = periodId != null ? context.read<PeriodProvider>().getPeriodById(int.parse(periodId)) : null;
                final DateTime? focusedDay = state.uri.queryParameters['focusedDay'] != null ? DateTime.parse(state.uri.queryParameters['focusedDay']!) : null;
                return LogPeriodPage(isEditing: isEditing, period: period, focusedDay: focusedDay);
              },
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) {
                return NotificationsPage();
              },
            ),
            GoRoute(
              path: 'about',
              builder: (context, state) {
                return AboutPage();
              },
            ),
            GoRoute(
              path: 'animal',
              builder: (context, state) {
                return AnimalGeneratorPage();
              },
            ),
          ],
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
          routes: [GoRoute(path: 'restore', builder: (context, state) => const OnboardingRestoreDataPage())],
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) {
            final String initialTab = state.uri.queryParameters['initialPage'] ?? 'restore';
            return RestoreHelpPage(initialTab: initialTab);
          },
        ),
        GoRoute(
          path: '/restore',
          builder: (context, state) => RestoreDataPreviewPage(sharedFiles: _sharedFiles),
        ),
      ],
      redirect: (context, state) async {
        final bool fileShared = await getFileShared() == true;
        if (_sharedFiles.isNotEmpty && fileShared) {
          return '/restore';
        }
        return null; // no redirection
      },
      errorBuilder: (context, state) {
        return widget.showOnboarding ? const OnboardingScreen() : MainNavigation(isAfterRestore: widget.isAfterRestore);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // disable landscape mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final ThemeMode themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp.router(
      title: 'Period Tracker',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      scrollBehavior: const _NoBounceScrollBehavior(),
      debugShowCheckedModeBanner: kDebugMode,
      builder: (context, child) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color navColor = Theme.of(context).colorScheme.surface;
        final Brightness iconBrightness = isDark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness: iconBrightness,
            systemNavigationBarColor: navColor,
            systemNavigationBarDividerColor: navColor,
            systemNavigationBarIconBrightness: iconBrightness,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
    );
  }
}

/// Clamps scrolling: no bounce, no stretch glow.
class _NoBounceScrollBehavior extends MaterialScrollBehavior {
  const _NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

class MainNavigation extends StatefulWidget {
  final bool isAfterRestore;

  const MainNavigation({super.key, required this.isAfterRestore});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _exactPromptShown = false; // once per app session
  bool _awaitingExactGrant = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingExactGrant) _onReturnFromAlarmSettings();
  }

  /// Notifications are only reliable on time with exact alarms. Android 14+ needs the user to allow
  /// "Alarms & reminders" in system settings, so explain first and send them there.
  Future<void> _checkExactAlarms() async {
    if (_exactPromptShown || !mounted) return;
    final Settings? settings = context.read<SettingsProvider>().settings;
    if (settings == null || !settings.notificationsEnabled) return;
    if (await NotificationService().canScheduleExact() || !mounted) return;
    _exactPromptShown = true;

    final bool open = await showConfirm(
      context: context,
      title: 'Get reminders on time',
      message: 'To send your period reminders exactly on the day, allow "Alarms & reminders" for Period Tracker on the next screen.',
      confirmLabel: 'Open settings',
      cancelLabel: 'Not now',
    );
    if (open) {
      _awaitingExactGrant = true;
      await NotificationService().requestExactAlarmPermission();
    }
  }

  /// Alarms already queued stay inexact, so reschedule everything once exact is granted.
  Future<void> _onReturnFromAlarmSettings() async {
    _awaitingExactGrant = false;
    if (!await NotificationService().canScheduleExact() || !mounted) return;
    final Settings? settings = context.read<SettingsProvider>().settings;
    final User? user = context.read<UserProvider>().user;
    if (settings == null) return;
    final DateTime? next = context.read<PeriodProvider>().getNextPeriodDate(settings.predictionMode == 'dynamic', user?.cycleLength);
    await NotificationService().scheduleNotificationsForNextPeriod(next, settings.notificationDaysBefore, settings.notificationTime);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.isAfterRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkExactAlarms());
    }
    if (widget.isAfterRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showInfo(
          context: context,
          title: 'Data restored',
          message: 'All your data has been successfully restored from the $kBackupFileName file.',
          buttonLabel: 'Great!',
        );
        await NotificationService().requestPermissions();
        await _checkExactAlarms();
      });
    }
  }

  final List<Widget> pages = const [HomePage(), InsightsPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomTabBar(
        index: _selectedIndex,
        onChanged: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomTabItem(label: 'Today', icon: Icons.today_outlined, selectedIcon: Icons.today_rounded),
          BottomTabItem(label: 'Insights', icon: Icons.show_chart_rounded, selectedIcon: Icons.show_chart_rounded),
          BottomTabItem(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded),
        ],
      ),
    );
  }
}
