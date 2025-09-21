import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final location = ref.watch(userLocationProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Prayer Settings Section
          _buildSectionHeader('Prayer Settings'),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              ref: ref,
              title: 'Prayer Reminders',
              subtitle: 'Get notified for prayer times',
              value: preferences.prayerReminders,
              onChanged: () => ref.read(userPreferencesProvider.notifier).togglePrayerReminders(),
              icon: Icons.notifications,
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: 'Madhab Preference',
              subtitle: preferences.selectedMadhab,
              icon: Icons.school,
              onTap: () => _showMadhabSelector(context, ref),
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: 'Location Settings',
              subtitle: location.when(
                data: (loc) => '${loc.city}, ${loc.country}',
                loading: () => 'Loading...',
                error: (_, __) => 'Location unavailable',
              ),
              icon: Icons.location_on,
              onTap: () => _showLocationDialog(context, ref),
            ),
          ]),

          const SizedBox(height: 24),

          // App Appearance Section
          _buildSectionHeader('App Appearance'),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              ref: ref,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              value: preferences.darkMode,
              onChanged: () => ref.read(userPreferencesProvider.notifier).toggleDarkMode(),
              icon: Icons.dark_mode,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              context: context,
              ref: ref,
              title: 'Show Arabic Text',
              subtitle: 'Display Arabic text in prayers and Quran',
              value: preferences.showArabic,
              onChanged: () => ref.read(userPreferencesProvider.notifier).toggleArabicText(),
              icon: Icons.translate,
            ),
          ]),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              ref: ref,
              title: 'App Notifications',
              subtitle: 'Receive notifications from the app',
              value: preferences.notificationsEnabled,
              onChanged: () => ref.read(userPreferencesProvider.notifier).toggleNotifications(),
              icon: Icons.notifications_active,
            ),
          ]),

          const SizedBox(height: 24),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard([
            _buildListTile(
              context: context,
              title: 'Refresh Prayer Times',
              subtitle: 'Update prayer times for current location',
              icon: Icons.refresh,
              onTap: () => _refreshPrayerTimes(context, ref),
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: 'Reset Prayer Statistics',
              subtitle: 'Clear all prayer tracking data',
              icon: Icons.delete_outline,
              onTap: () => _showResetStatsDialog(context, ref),
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: 'Update Location',
              subtitle: 'Refresh your current location',
              icon: Icons.my_location,
              onTap: () => _updateLocation(context, ref),
            ),
          ]),

          const SizedBox(height: 40),

          // App Info
          _buildAppInfoCard(preferences),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Switch(
        value: value,
        onChanged: (_) => onChanged(),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      onTap: onChanged,
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.body1),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildAppInfoCard(UserPreferences preferences) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.mosque, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Noor - Islamic App',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Last used: ${_formatLastUsage(preferences.lastAppUsage)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showMadhabSelector(BuildContext context, WidgetRef ref) {
    final madhabs = [
      'Hanafi',
      'Maliki',
      'Shafi\'i',
      'Hanbali',
      'Jafari',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Madhab'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: madhabs.map((madhab) {
            return ListTile(
              title: Text(madhab),
              onTap: () {
                ref.read(userPreferencesProvider.notifier).updateMadhab(madhab);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Settings'),
        content: const Text(
          'Your location is used to calculate accurate prayer times. '
          'You can refresh your location or allow the app to use your current position.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateLocation(context, ref);
            },
            child: const Text('Update Location'),
          ),
        ],
      ),
    );
  }

  void _refreshPrayerTimes(BuildContext context, WidgetRef ref) {
    ref.read(prayerTimesProvider.notifier).refreshPrayerTimes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing prayer times...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateLocation(BuildContext context, WidgetRef ref) {
    ref.read(userLocationProvider.notifier).refreshLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating location...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showResetStatsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics'),
        content: const Text(
          'This will permanently delete all your prayer tracking data, including streaks and completion history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetStatistics(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetStatistics(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // Clear all prayer-related preferences
      final keysToRemove = prefs.getKeys().where((key) =>
        key.startsWith('prayer_') ||
        key.startsWith('total_prayers') ||
        key.startsWith('longest_streak') ||
        key.startsWith('last_prayer_time')
      ).toList();

      for (String key in keysToRemove) {
        await prefs.remove(key);
      }

      // Refresh the providers to reflect the changes
      ref.read(prayerStatsProvider.notifier).refreshStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prayer statistics have been reset'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting statistics: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatLastUsage(String lastUsage) {
    if (lastUsage == 'First time') return lastUsage;

    try {
      final DateTime lastUsed = DateTime.parse(lastUsage);
      final Duration difference = DateTime.now().difference(lastUsed);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return lastUsage;
    }
  }
}
