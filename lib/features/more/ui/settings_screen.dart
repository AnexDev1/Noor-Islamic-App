import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import '../../../core/services/adhan_notification_service.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final location = ref.watch(userLocationProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.settings),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Prayer Settings Section
          _buildSectionHeader(l10n.prayerTimes),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              ref: ref,
              title: l10n.prayerReminders,
              subtitle: l10n.prayerRemindersDesc,
              value: preferences.prayerReminders,
              onChanged: () => ref
                  .read(userPreferencesProvider.notifier)
                  .togglePrayerReminders(),
              icon: Icons.notifications,
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: l10n.madhabPreference,
              subtitle: preferences.selectedMadhab,
              icon: Icons.school,
              onTap: () => _showMadhabSelector(context, ref),
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: l10n.updateLocation,
              subtitle: location.when(
                data: (loc) => '${loc.city}, ${loc.country}',
                loading: () => l10n.loading,
                error: (_, __) => l10n.error,
              ),
              icon: Icons.location_on,
              onTap: () => _showLocationDialog(context, ref),
            ),
          ]),

          const SizedBox(height: 24),

          // Language Settings Section
          _buildSectionHeader('${l10n.language} / ቋንቋ'),
          _buildSettingsCard([_buildLanguageTile(context, ref)]),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader(l10n.notifications),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              ref: ref,
              title: l10n.notifications,
              subtitle: l10n.adhanNotificationsDesc,
              value: preferences.notificationsEnabled,
              onChanged: () => ref
                  .read(userPreferencesProvider.notifier)
                  .toggleNotifications(),
              icon: Icons.notifications_active,
            ),
            const Divider(height: 1),
            _buildAdhanNotificationTile(context, ref),
            const Divider(height: 1),
            _buildReminderNotificationTile(context, ref),
          ]),
          const SizedBox(height: 12),

          // Test Notifications Section
          _buildSectionHeader(l10n.notifications),
          _buildSettingsCard([
            _buildTestNotificationTile(
              context,
              l10n.testAdhanNotification,
              () => _testAdhanNotification(context),
            ),
            const Divider(height: 1),
            _buildTestNotificationTile(
              context,
              l10n.testReminderNotification,
              () => _testReminderNotification(context),
            ),
          ]),

          const SizedBox(height: 24),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard([
            _buildListTile(
              context: context,
              title: l10n.refreshPrayerTimes,
              subtitle: l10n.refreshPrayerTimesDesc,
              icon: Icons.refresh,
              onTap: () => _refreshPrayerTimes(context, ref),
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: l10n.resetStatistics,
              subtitle: l10n.resetPrayerStatisticsDesc,
              icon: Icons.delete_outline,
              onTap: () => _showResetStatsDialog(context, ref),
            ),
            const Divider(height: 1),
            _buildListTile(
              context: context,
              title: l10n.updateLocation,
              subtitle: l10n.updateLocationDesc,
              icon: Icons.my_location,
              onTap: () => _updateLocation(context, ref),
            ),
          ]),

          const SizedBox(height: 40),

          // App Info
          _buildAppInfoCard(context, preferences),
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

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(Icons.language, color: AppColors.primary),
      title: Text(l10n.language, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        localeNotifier.getLocaleName(currentLocale),
        style: AppTextStyles.caption,
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => _showLanguageSelector(context, ref),
    );
  }

  Widget _buildAdhanNotificationTile(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: AdhanNotificationService.areNotificationsEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? true;
        return ListTile(
          leading: Icon(Icons.mosque, color: AppColors.primary),
          title: Text(l10n.adhanNotifications, style: AppTextStyles.bodyLarge),
          subtitle: Text(
            l10n.adhanNotificationsDesc,
            style: AppTextStyles.caption,
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) async {
              await AdhanNotificationService.setNotificationsEnabled(value);
              // Force rebuild
              (context as Element).markNeedsBuild();
            },
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
        );
      },
    );
  }

  Widget _buildTestNotificationTile(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Icon(Icons.notifications_active, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(l10n.tapToTestNotification, style: AppTextStyles.caption),
      trailing: Icon(Icons.play_arrow, color: AppColors.primary),
      onTap: onTap,
    );
  }

  Widget _buildReminderNotificationTile(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: AdhanNotificationService.areRemindersEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? true;
        return ListTile(
          leading: Icon(Icons.alarm, color: AppColors.primary),
          title: Text(l10n.prayerReminders, style: AppTextStyles.bodyLarge),
          subtitle: Text(
            l10n.prayerRemindersDesc,
            style: AppTextStyles.caption,
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) async {
              await AdhanNotificationService.setRemindersEnabled(value);
              // Force rebuild
              (context as Element).markNeedsBuild();
            },
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
        );
      },
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

  Widget _buildAppInfoCard(BuildContext context, UserPreferences preferences) {
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
            AppLocalizations.of(context)!.appTitle,
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
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showMadhabSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final madhabs = ['Hanafi', 'Maliki', 'Shafi\'i', 'Hanbali', 'Jafari'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectMadhab),
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
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final languages = [
      {
        'locale': const Locale('en'),
        'name': 'English',
        'nativeName': 'English',
      },
      {'locale': const Locale('am'), 'name': 'Amharic', 'nativeName': 'አማርኛ'},
      {
        'locale': const Locale('om'),
        'name': 'Afan Oromo',
        'nativeName': 'Afaan Oromoo',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.selectLanguage} / ቋንቋ ይምረጡ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final locale = lang['locale'] as Locale;
            final isSelected =
                currentLocale.languageCode == locale.languageCode;
            return ListTile(
              leading: isSelected
                  ? Icon(Icons.check_circle, color: AppColors.primary)
                  : Icon(Icons.circle_outlined, color: AppColors.textSecondary),
              title: Text(lang['nativeName'] as String),
              subtitle: Text(lang['name'] as String),
              onTap: () {
                localeNotifier.setLocale(locale);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.language} changed to ${lang['name']}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.updateLocation),
        content: const Text(
          'Your location is used to calculate accurate prayer times. '
          'You can refresh your location or allow the app to use your current position.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateLocation(context, ref);
            },
            child: Text(l10n.updateLocation),
          ),
        ],
      ),
    );
  }

  void _refreshPrayerTimes(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(prayerTimesProvider.notifier).refreshPrayerTimes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.refreshingPrayerTimes),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateLocation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(userLocationProvider.notifier).refreshLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.updatingLocation),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetStatsDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetStatistics),
        content: const Text(
          'This will permanently delete all your prayer tracking data, including streaks and completion history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetStatistics(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.resetStatistics),
          ),
        ],
      ),
    );
  }

  Future<void> _resetStatistics(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // Clear all prayer-related preferences
      final keysToRemove = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith('prayer_') ||
                key.startsWith('total_prayers') ||
                key.startsWith('longest_streak') ||
                key.startsWith('last_prayer_time'),
          )
          .toList();

      for (String key in keysToRemove) {
        await prefs.remove(key);
      }

      // Refresh the providers to reflect the changes
      ref.read(prayerStatsProvider.notifier).refreshStats();

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetStatistics),
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

  void _testAdhanNotification(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await AdhanNotificationService.testAdhanNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.adhanNotificationSent),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _testReminderNotification(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await AdhanNotificationService.testReminderNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reminderNotificationSent),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
