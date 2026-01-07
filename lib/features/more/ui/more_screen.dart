import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/user_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import 'settings_screen.dart';
import 'islamic_calendar_screen.dart';
import 'about_screen.dart';
import 'profile_edit_screen.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'More'),
      body: LiquidPullToRefresh(
        animSpeedFactor: 3,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        showChildOpacityTransition: true,
        onRefresh: () async {
          // Refresh user data or other non-prayer stats
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                _buildUserProfileHeader(),
                const SizedBox(height: 24),
                _buildSectionHeader('Progress & Analytics'),
                const SizedBox(height: 12),
                _buildAnalyticsSection(),
                const SizedBox(height: 24),
                _buildSectionHeader('Settings'),
                const SizedBox(height: 12),
                _buildSettingsSection(),
                const SizedBox(height: 24),
                _buildSectionHeader('Support & Community'),
                const SizedBox(height: 12),
                _buildSupportSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return CustomCard(
      child: Row(
        children: [
          FutureBuilder<String>(
            future: UserService.getUserGender(),
            builder: (context, genderSnapshot) {
              String gender = (genderSnapshot.data ?? 'Male').toLowerCase();
              String asset = gender == 'female'
                  ? 'assets/female.png'
                  : 'assets/male.png';
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(18), // Rounded square
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FutureBuilder<String>(
              future: UserService.getIslamicGreeting(),
              builder: (context, greetingSnapshot) {
                return FutureBuilder<String>(
                  future: UserService.getUserName(),
                  builder: (context, nameSnapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingSnapshot.data ?? 'As-salamu Alaykum',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nameSnapshot.data ?? 'Abdullah',
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => _editProfile(),
            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.calendar_month,
          title: 'Islamic Calendar',
          subtitle: 'Hijri dates and Islamic events',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IslamicCalendarScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.settings,
          title: 'App Settings',
          subtitle: 'Notifications, theme, language',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.location_on,
          title: 'Location Settings',
          subtitle: 'Update prayer location',
          onTap: () => _showLocationSettings(),
        ),
        _buildMenuTile(
          icon: Icons.backup,
          title: 'Backup & Sync',
          subtitle: 'Save your progress',
          onTap: () => _showBackupOptions(),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.star,
          title: 'Rate Noor',
          subtitle: 'Love the app? Rate us!',
          onTap: () => _rateApp(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 12,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        _buildMenuTile(
          icon: Icons.share,
          title: 'Share with Friends',
          subtitle: 'Spread the word',
          onTap: () => _shareApp(),
        ),
        _buildMenuTile(
          icon: Icons.feedback,
          title: 'Feedback',
          subtitle: 'Help us improve',
          onTap: () => _sendFeedback(),
        ),
        _buildMenuTile(
          icon: Icons.info,
          title: 'About Noor',
          subtitle: 'App info, privacy & terms',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMenuTile({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  iconWidget ??
                  (icon != null
                      ? Icon(icon, color: AppColors.primary, size: 20)
                      : null),
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
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    );

    if (result == true) {
      // Refresh prayer stats after profile update
      ref.read(prayerStatsProvider.notifier).refreshStats();
    }
  }

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Settings'),
        content: const Text(
          'Update your location for accurate prayer times and Qibla direction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Update location using Riverpod provider
              ref.read(userLocationProvider.notifier).refreshLocation();
              AppHelpers.showSnackBar(context, 'Updating location...');
            },
            child: const Text('Update Location'),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Sync'),
        content: const Text(
          'Backup your prayer history, bookmarks, and app settings to the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppHelpers.showSnackBar(context, 'Backup created successfully');
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    // In a real app, this would open the app store
    AppHelpers.showSnackBar(context, 'Thank you! Redirecting to app store...');
  }

  Future<void> _shareApp() async {
    AppHelpers.showSnackBar(context, 'Sharing Noor app with friends...');
  }

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'feedback@noorapp.com',
      query: 'subject=Noor App Feedback',
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      AppHelpers.showSnackBar(context, 'Could not open email client');
    }
  }
}
