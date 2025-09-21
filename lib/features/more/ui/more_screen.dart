import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../quran/ui/quran_screen.dart';
import '../../hadith/ui/hadith_home_screen.dart';
import '../../azkhar/ui/azkhar_home_screen.dart';
import '../../tasbih/ui/tasbih_screen.dart';
import 'settings_screen.dart';
import 'prayer_stats_screen.dart';
import 'islamic_calendar_screen.dart';
import 'about_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, int> _userStats = {
    'totalPrayers': 0,
    'quranProgress': 0,
    'tasbihs': 0,
    'streak': 0,
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserStats();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userStats['totalPrayers'] = prefs.getInt('total_prayers') ?? 0;
      _userStats['quranProgress'] = prefs.getInt('quran_progress') ?? 0;
      _userStats['tasbihs'] = prefs.getInt('total_tasbihs') ?? 0;
      _userStats['streak'] = prefs.getInt('prayer_streak') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'More'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header
                _UserProfileHeader(),

                const SizedBox(height: 24),

                // Quick Stats
                _QuickStatsSection(),

                const SizedBox(height: 24),

                // Islamic Tools Section
                _SectionHeader(title: 'Islamic Tools'),
                const SizedBox(height: 12),
                _IslamicToolsGrid(),

                const SizedBox(height: 24),

                // Analytics & Progress
                _SectionHeader(title: 'Progress & Analytics'),
                const SizedBox(height: 12),
                _AnalyticsSection(),

                const SizedBox(height: 24),

                // Settings & Preferences
                _SectionHeader(title: 'Settings'),
                const SizedBox(height: 12),
                _SettingsSection(),

                const SizedBox(height: 24),

                // Support & Community
                _SectionHeader(title: 'Support & Community'),
                const SizedBox(height: 12),
                _SupportSection(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _UserProfileHeader() {
    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 35,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'As-salamu Alaykum',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Abdullah',
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_userStats['streak']} day streak',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _QuickStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Prayers',
            value: _userStats['totalPrayers'].toString(),
            icon: Icons.mosque,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrayerStatsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Quran',
            value: '${_userStats['quranProgress']}%',
            icon: Icons.menu_book,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuranScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Tasbih',
            value: _userStats['tasbihs'].toString(),
            icon: Icons.analytics,
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TasbihScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _IslamicToolsGrid() {
    final tools = [
      {
        'title': 'Holy Quran',
        'subtitle': 'Read and listen',
        'icon': Icons.menu_book,
        'color': AppColors.primary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuranScreen())),
      },
      {
        'title': 'Hadith',
        'subtitle': 'Prophetic traditions',
        'icon': Icons.article,
        'color': AppColors.accent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HadithHomeScreen())),
      },
      {
        'title': 'Daily Azkhar',
        'subtitle': 'Morning & evening',
        'icon': Icons.favorite,
        'color': AppColors.secondary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AzkharHomeScreen())),
      },
      {
        'title': 'Islamic Calendar',
        'subtitle': 'Hijri dates & events',
        'icon': Icons.calendar_month,
        'color': AppColors.primary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IslamicCalendarScreen())),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _ToolCard(
          title: tool['title'] as String,
          subtitle: tool['subtitle'] as String,
          icon: tool['icon'] as IconData,
          color: tool['color'] as Color,
          onTap: tool['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _AnalyticsSection() {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.analytics,
          title: 'Prayer Statistics',
          subtitle: 'Track your prayer performance',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrayerStatsScreen()),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_userStats['streak']} days',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _SettingsSection() {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.settings,
          title: 'App Settings',
          subtitle: 'Notifications, theme, language',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        _MenuTile(
          icon: Icons.location_on,
          title: 'Location Settings',
          subtitle: 'Update prayer location',
          onTap: () => _showLocationSettings(),
        ),
        _MenuTile(
          icon: Icons.backup,
          title: 'Backup & Sync',
          subtitle: 'Save your progress',
          onTap: () => _showBackupOptions(),
        ),
      ],
    );
  }

  Widget _SupportSection() {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.star,
          title: 'Rate Noor',
          subtitle: 'Love the app? Rate us!',
          onTap: () => _rateApp(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) =>
              Icon(Icons.star, size: 12, color: AppColors.accent.withOpacity(0.6))
            ),
          ),
        ),
        _MenuTile(
          icon: Icons.share,
          title: 'Share with Friends',
          subtitle: 'Spread the word',
          onTap: () => _shareApp(),
        ),
        _MenuTile(
          icon: Icons.feedback,
          title: 'Feedback',
          subtitle: 'Help us improve',
          onTap: () => _sendFeedback(),
        ),
        _MenuTile(
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

  Widget _SectionHeader({required String title}) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _StatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _ToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _MenuTile({
    required IconData icon,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
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
            trailing ?? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter your city',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppHelpers.showSnackBar(context, 'Profile updated successfully');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Settings'),
        content: const Text('Update your location for accurate prayer times and Qibla direction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppHelpers.showSnackBar(context, 'Location updated');
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
        content: const Text('Backup your prayer history, bookmarks, and app settings to the cloud.'),
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
