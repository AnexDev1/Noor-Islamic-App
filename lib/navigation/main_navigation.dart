import 'package:flutter/material.dart';
import '../features/home/ui/home_screen.dart';
import '../features/qibla/ui/qibla_screen.dart';
import '../features/ai_chat/ui/ai_chat_screen.dart';
import '../features/more/ui/more_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QiblaScreen(),
    const AiChatScreen(),
    const MoreScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Qibla',
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'AI Chat',
    ),
    NavigationItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _navigationItems.asMap().entries.map((entry) {
                final int index = entry.key;
                final NavigationItem item = entry.value;
                final bool isActive = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 24,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
