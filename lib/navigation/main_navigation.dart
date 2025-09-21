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
      icon: Image.asset('assets/masjid.png', height: 24, color: AppColors.textTertiary),
      activeIcon: Image.asset('assets/masjid.png', height: 24, color: AppColors.primary),
      label: 'Home',
    ),
    NavigationItem(
      icon: Image.asset('assets/qibla.png', height: 24, color: AppColors.textTertiary),
      activeIcon: Image.asset('assets/qibla.png', height: 24, color: AppColors.primary),
      label: 'Qibla',
    ),
    NavigationItem(
      icon: Image.asset('assets/chat.png', height: 24, color: AppColors.textTertiary),
      activeIcon: Image.asset('assets/chat.png', height: 24, color: AppColors.primary),
      label: 'AI Chat',
    ),
    NavigationItem(
      icon: Image.asset('assets/more.png', height: 24, color: AppColors.textTertiary),
      activeIcon: Image.asset('assets/more.png', height: 24, color: AppColors.primary),
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
                            child: item.icon is Widget || item.activeIcon is Widget
                              ? (isActive ? item.activeIcon : item.icon)
                              : Icon(
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
  final dynamic icon; // IconData or Widget
  final dynamic activeIcon; // IconData or Widget
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
