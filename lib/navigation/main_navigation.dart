import 'package:flutter/material.dart';

import '../features/home/ui/home_screen.dart';
import '../features/more/ui/more_screen.dart';
import '../features/qibla/ui/qibla_screen.dart';
import '../features/videos/ui/ustaz_list_screen.dart';
import '../l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    QiblaScreen(),
    UstazListScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: l10n.qiblaDirection,
          ),
          NavigationDestination(
            icon: const Icon(Icons.ondemand_video_outlined),
            selectedIcon: const Icon(Icons.ondemand_video_rounded),
            label: l10n.islamicVideos,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: l10n.more,
          ),
        ],
      ),
    );
  }
}
