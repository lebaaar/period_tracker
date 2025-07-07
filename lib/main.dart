import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/period_provider.dart';
import 'package:period_tracker/theme.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/insights_page.dart';
import 'pages/profile_page.dart';
import 'pages/log_period_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PeriodProvider())],
      child: PeriodTrackerApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigation(),
      routes: [
        GoRoute(
          path: 'log',
          builder: (context, state) => const LogPeriodPage(),
        ),
      ],
    ),
  ],
);

class PeriodTrackerApp extends StatelessWidget {
  const PeriodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Period Tracker',
      theme: appTheme,
      routerConfig: _router,
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

  @override
  Widget build(BuildContext context) {
    final pages = [HomePage(), InsightsPage(), ProfilePage()];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: null,
          ),
          // timeline, pie_cjart, insights
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
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
