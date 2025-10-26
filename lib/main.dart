import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  // Set system UI overlay style globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Background behind status bar (top)
      statusBarBrightness:
          Brightness.dark, // iOS: dark status bar content (light icons/text)
      statusBarIconBrightness:
          Brightness.light, // Android: light icons (dark background)
      systemNavigationBarColor:
          Colors.black, // Android: background color of bottom navigation bar
      systemNavigationBarDividerColor:
          Colors.black, // Android: divider above navbar (optional)
      systemNavigationBarIconBrightness:
          Brightness.light, // Android: light icons for dark navbar
      systemStatusBarContrastEnforced: false, // Allow custom navbar styling
      systemNavigationBarContrastEnforced: false, // Allow custom navbar styling
    ),
  );

  final bool onBoardingComplete = await getOnboardingComplete();
  final bool displayRestoreSuccess = await getDisplayRestoreSuccess();
  if (displayRestoreSuccess) {
    await clearDisplayRestoreSuccess();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PeriodProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: PeriodTrackerApp(
        showOnboarding: !onBoardingComplete,
        displayRestoreSuccess: displayRestoreSuccess,
      ),
    ),
  );
}

class PeriodTrackerApp extends StatefulWidget {
  final bool showOnboarding;
  final bool displayRestoreSuccess;
  const PeriodTrackerApp({
    super.key,
    required this.showOnboarding,
    required this.displayRestoreSuccess,
  });

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
          builder: (context, state) => MainNavigation(
            displayRestoreSuccess: widget.displayRestoreSuccess,
          ),
          routes: [
            GoRoute(
              path: 'log',
              builder: (context, state) {
                final isEditing =
                    state.uri.queryParameters['isEditing'] == 'true';
                final periodId = state.uri.queryParameters['periodId'];
                final period = periodId != null
                    ? context.read<PeriodProvider>().getPeriodById(
                        int.parse(periodId),
                      )
                    : null;
                final focusedDay =
                    state.uri.queryParameters['focusedDay'] != null
                    ? DateTime.parse(state.uri.queryParameters['focusedDay']!)
                    : null;
                return LogPeriodPage(
                  isEditing: isEditing,
                  period: period,
                  focusedDay: focusedDay,
                );
              },
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) {
                return NotificationsPage();
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
          routes: [
            GoRoute(
              path: 'restore',
              builder: (context, state) => const OnboardingRestoreDataPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) {
            final String initialTab =
                state.uri.queryParameters['initialPage'] ?? 'restore';
            return RestoreHelpPage(initialTab: initialTab);
          },
        ),
        GoRoute(
          path: '/restore',
          builder: (context, state) =>
              RestoreDataPreviewPage(sharedFiles: _sharedFiles),
        ),
      ],
      redirect: (context, state) async {
        bool fileShared = await getFileShared() == true;
        if (_sharedFiles.isNotEmpty && fileShared) {
          return '/restore';
        }
        return null; // no redirection
      },
      errorBuilder: (context, state) {
        return widget.showOnboarding
            ? const OnboardingScreen()
            : MainNavigation(
                displayRestoreSuccess: widget.displayRestoreSuccess,
              );
      },
    );

    // disable landscape mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp.router(
      title: 'Period Tracker',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  final bool displayRestoreSuccess;

  const MainNavigation({super.key, required this.displayRestoreSuccess});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.displayRestoreSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Data successfully restored 🎉'),
            content: Text(
              'All your data has been successfully restored from the $kBackupFileName file.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
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

  final pages = [HomePage(), InsightsPage(), ProfilePage()];
  final List<String> appBarTitles = ['Home', 'Insights', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitles[_selectedIndex],
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: 'Home',
            tooltip: null,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(
              Icons.bar_chart_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
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
