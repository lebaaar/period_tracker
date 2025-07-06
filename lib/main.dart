import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/theme.dart';
import 'home_page.dart';
import 'insights_page.dart';
import 'user_page.dart';
import 'log_period_page.dart';

void main() {
  runApp(const PeriodTrackerApp());
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
      theme: appTheme, // from theme.dart
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
    final pages = [
      HomePage(isSelected: _selectedIndex == 0),
      InsightsPage(isSelected: _selectedIndex == 1),
      UserPage(isSelected: _selectedIndex == 2),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: null,
          ),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
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
