import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/pages/onboarding_screen.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/user_data_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/insights_page.dart';
import 'pages/profile_page.dart';
import 'pages/log_period_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final prefs = await SharedPreferences.getInstance();
  bool onBoardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PeriodProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: PeriodTrackerApp(showOnboarding: !onBoardingComplete),
    ),
  );
}

class PeriodTrackerApp extends StatelessWidget {
  const PeriodTrackerApp({super.key, required this.showOnboarding});
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: showOnboarding ? '/onboarding' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainNavigation(),
          routes: [
            GoRoute(
              path: '/log',
              builder: (context, state) => const LogPeriodPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Period Tracker',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final pages = [HomePage(), InsightsPage(), ProfilePage()];
  final List<String> appBarTitles = ['Home', 'Insights', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitles[_selectedIndex],
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await UserDataService().clearAppData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App data cleared!')),
                );
                context.go('/onboarding');
              }
            },
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: 'Home',
            tooltip: null,
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline),
            selectedIcon: Icon(
              Icons.timeline,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            selectedIcon: Icon(
              Icons.person,
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // go_router navigation
                context.go('/log');
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99.0),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
