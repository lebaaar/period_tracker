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
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:period_tracker/theme.dart';
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

  // Set system UI overlay style globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Background behind status bar (top)
      statusBarBrightness: Brightness.dark, // iOS: dark status bar content (light icons/text)
      statusBarIconBrightness: Brightness.light, // Android: light icons (dark background)
      systemNavigationBarColor: Colors.black, // Android: background color of bottom navigation bar
      systemNavigationBarDividerColor: Colors.black, // Android: divider above navbar (optional)
      systemNavigationBarIconBrightness: Brightness.light, // Android: light icons for dark navbar
      systemStatusBarContrastEnforced: false, // Allow custom navbar styling
      systemNavigationBarContrastEnforced: false, // Allow custom navbar styling
    ),
  );

  final bool onBoardingComplete = await getOnboardingComplete();
  final bool isAfterRestore = await getDisplayRestoreSuccess();
  if (isAfterRestore) {
    await clearDisplayRestoreSuccess();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PeriodProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
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
                final DateTime? focusedDay = state.uri.queryParameters['focusedDay'] != null
                    ? DateTime.parse(state.uri.queryParameters['focusedDay']!)
                    : null;
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

    // disable landscape mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp.router(title: 'Period Tracker', theme: appTheme, routerConfig: router, debugShowCheckedModeBanner: kDebugMode);
  }
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

    final bool? open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get reminders on time'),
        content: const Text('To send your period reminders exactly on the day, allow "Alarms & reminders" for Period Tracker on the next screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.tertiary),
            child: const Text('Not now'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Open settings')),
        ],
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
    if (open == true) {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Data restored successfully 🎉'),
            content: Text('All your data has been successfully restored from the $kBackupFileName file'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await NotificationService().requestPermissions();
                  await _checkExactAlarms();
                },
                child: const Text('Great!'),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      });
    }
  }

  final List<Widget> pages = [HomePage(), InsightsPage(), ProfilePage()];
  final List<String> appBarTitles = ['Home', 'Insights', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_selectedIndex], style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(padding: EdgeInsets.all(8.0), child: pages[_selectedIndex]),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded, color: Theme.of(context).colorScheme.onPrimary),
            label: 'Home',
            tooltip: null,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Theme.of(context).colorScheme.onPrimary),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.onPrimary),
            label: 'Profile',
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
