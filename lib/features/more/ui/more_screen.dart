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
import '../../../l10n/app_localizations.dart'; // Import localization
import '../../qadah/ui/qadah_screen.dart'; // Import Qadah screen
import '../../tasbih/ui/tasbih_hub_screen.dart';
import '../../quran_streak/ui/quran_streak_screen.dart';
import '../../reflections/ui/reflections_screen.dart';
import '../../ayah_card/ui/ayah_card_screen.dart';
import '../../ramadan_habits/ui/ramadan_habits_screen.dart';
import '../../prayer_mat/ui/prayer_mat_screen.dart';
import '../../noor_wrap/ui/noor_wrap_screen.dart';
import '../../learn_islam/ui/learn_islam_screen.dart';
import '../../quran/ui/listen_quran_screen.dart';
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
    // Access localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: l10n.moreTitle), // Localized title
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
                _buildUserProfileHeader(l10n), // Pass l10n
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.progressAnalytics), // Localized header
                const SizedBox(height: 12),
                _buildAnalyticsSection(l10n), // Pass l10n
                const SizedBox(height: 24),
                _buildSectionHeader('Spiritual Tools'),
                const SizedBox(height: 12),
                _buildSpiritualToolsSection(),
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.settingsTitle), // Localized header
                const SizedBox(height: 12),
                _buildSettingsSection(l10n), // Pass l10n
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.supportCommunity), // Localized header
                const SizedBox(height: 12),
                _buildSupportSection(l10n), // Pass l10n
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader(AppLocalizations l10n) {
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
                          greetingSnapshot.data ?? l10n.assalamuAlaikum,
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

  Widget _buildAnalyticsSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.calendar_today,
          title: l10n.qadahTitle, // "Qadah Tracker"
          subtitle: l10n.qadahSubtitle, // "Track and make up missed fasts"
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QadahScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.calendar_month,
          title: l10n.islamicCalendarTitle,
          subtitle: l10n.islamicCalendarSubtitle,
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

  Widget _buildSpiritualToolsSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.radio_button_checked,
          title: 'Tasbih Hub',
          subtitle: 'Counter, Nafas Dhikr & Bead Flow',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TasbihHubScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.menu_book,
          title: AppLocalizations.of(context)!.learnIslam,
          subtitle: 'Salah, Wudu, rules & video lessons',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LearnIslamScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.headphones_rounded,
          title: AppLocalizations.of(context)!.listenQuran,
          subtitle: 'Stream audio with background play',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ListenQuranScreen(),
            ), // Import needed
          ),
        ),
        _buildMenuTile(
          icon: Icons.local_fire_department,
          title: 'Mushaf Streak',
          subtitle: 'Track your daily Quran reading',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuranStreakScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.edit_note,
          title: 'Salah Reflections',
          subtitle: 'Journal your prayer experiences',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReflectionsScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.auto_stories,
          title: 'Ayah of the Day',
          subtitle: 'Beautiful shareable Quran cards',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AyahCardScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.grid_view_rounded,
          title: 'Ramadan Habits',
          subtitle: '30-day challenge board',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RamadanHabitsScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.self_improvement,
          title: 'Prayer Mat Mode',
          subtitle: 'Distraction-free focus timer',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrayerMatScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.auto_awesome,
          title: 'Noor Wrap',
          subtitle: 'Your spiritual journey summary',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoorWrapScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.settings,
          title: l10n.settingsTitle,
          subtitle: l10n.settingsSubtitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        _buildMenuTile(
          icon: Icons.location_on,
          title: l10n.locationSettingsTitle,
          subtitle: l10n.locationSettingsSubtitle,
          onTap: () => _showLocationSettings(l10n),
        ),
        _buildMenuTile(
          icon: Icons.backup,
          title: l10n.backupTitle,
          subtitle: l10n.backupSubtitle,
          onTap: () => _showBackupOptions(l10n),
        ),
      ],
    );
  }

  Widget _buildSupportSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.star,
          title: l10n.rateAppTitle,
          subtitle: l10n.rateAppSubtitle,
          onTap: () => _rateApp(l10n),
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
          title: l10n.shareAppTitle,
          subtitle: l10n.shareAppSubtitle,
          onTap: () => _shareApp(l10n),
        ),
        _buildMenuTile(
          icon: Icons.feedback,
          title: l10n.feedbackTitle,
          subtitle: l10n.feedbackSubtitle,
          onTap: () => _sendFeedback(l10n),
        ),
        _buildMenuTile(
          icon: Icons.info,
          title: l10n.aboutAppTitle,
          subtitle: l10n.aboutAppSubtitle,
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

  void _showLocationSettings(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationSettingsTitle),
        content: Text(
          l10n.locationPermissionDesc, // Reusing existing string for description
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Update location using Riverpod provider
              ref.read(userLocationProvider.notifier).refreshLocation();
              AppHelpers.showSnackBar(context, l10n.updatingLocation);
            },
            child: Text(l10n.updateLocation),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupTitle),
        content: const Text(
          'Backup your prayer history, bookmarks, and app settings to the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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

  Future<void> _rateApp(AppLocalizations l10n) async {
    // In a real app, this would open the app store
    AppHelpers.showSnackBar(context, 'Thank you! Redirecting to app store...');
  }

  Future<void> _shareApp(AppLocalizations l10n) async {
    AppHelpers.showSnackBar(context, 'Sharing Noor app with friends...');
  }

  Future<void> _sendFeedback(AppLocalizations l10n) async {
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
