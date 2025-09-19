import 'package:flutter/material.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'More'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            const _ProfileSection(),

            const SizedBox(height: 24),

            // Settings Section
            const _SettingsSection(),

            const SizedBox(height: 24),

            // Islamic Tools Section
            const _IslamicToolsSection(),

            const SizedBox(height: 24),

            // Support Section
            const _SupportSection(),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Abdullah',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 4),
          Text(
            'Muslim since 2020',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(title: 'Prayers', value: '1,247'),
              _StatItem(title: 'Duas Read', value: '89'),
              _StatItem(title: 'Tasbih', value: '3,456'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 12),
        _SettingsItem(
          icon: Icons.notifications,
          title: 'Prayer Notifications',
          subtitle: 'Configure prayer time alerts',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.language,
          title: 'Language',
          subtitle: 'English, Arabic, Urdu',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.dark_mode,
          title: 'Theme',
          subtitle: 'Light, Dark, System',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.location_on,
          title: 'Location',
          subtitle: 'Set your prayer location',
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    AppHelpers.showSnackBar(context, 'Feature coming soon!');
  }
}

class _IslamicToolsSection extends StatelessWidget {
  const _IslamicToolsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Islamic Tools',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 12),
        _SettingsItem(
          icon: Icons.schedule,
          title: 'Prayer Times',
          subtitle: 'View daily prayer schedule',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.calendar_month,
          title: 'Islamic Calendar',
          subtitle: 'Hijri dates and events',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.mosque,
          title: 'Nearby Mosques',
          subtitle: 'Find mosques around you',
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    AppHelpers.showSnackBar(context, 'Feature coming soon!');
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support & Info',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 12),
        _SettingsItem(
          icon: Icons.help,
          title: 'Help & FAQ',
          subtitle: 'Get help and answers',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.star,
          title: 'Rate App',
          subtitle: 'Rate us on the store',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.share,
          title: 'Share App',
          subtitle: 'Share with friends and family',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsItem(
          icon: Icons.info,
          title: 'About',
          subtitle: 'App version and information',
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    AppHelpers.showSnackBar(context, 'Feature coming soon!');
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
