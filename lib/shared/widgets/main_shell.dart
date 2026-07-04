import 'package:flutter/material.dart';
import 'package:ended/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ended/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:ended/features/history/presentation/screens/history_screen.dart';
import 'package:ended/features/settings/presentation/screens/settings_screen.dart';

/// Main app shell with bottom navigation bar.
/// 5 tabs: Home, Statistics, History, Settings.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
    BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
    );
  }
}
