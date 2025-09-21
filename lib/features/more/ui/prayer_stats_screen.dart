import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';
import 'dart:convert';

class PrayerStatsScreen extends StatefulWidget {
  const PrayerStatsScreen({super.key});

  @override
  State<PrayerStatsScreen> createState() => _PrayerStatsScreenState();
}

class _PrayerStatsScreenState extends State<PrayerStatsScreen> with TickerProviderStateMixin {
  Map<String, int> _prayerCounts = {};
  int _totalPrayers = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPrayerStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('prayer_stats') ?? '{}';
    final activityJson = prefs.getString('prayer_activity') ?? '[]';

    setState(() {
      _prayerCounts = Map<String, int>.from(json.decode(statsJson));
      _recentActivity = List<Map<String, dynamic>>.from(json.decode(activityJson));
      _calculateStats();
    });
  }

  void _calculateStats() {
    _totalPrayers = _prayerCounts.values.fold(0, (sum, count) => sum + count);
    _currentStreak = _calculateCurrentStreak();
    _longestStreak = _calculateLongestStreak();
  }

  int _calculateCurrentStreak() {
    // Calculate current consecutive days of completing all 5 prayers
    int streak = 0;
    DateTime today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      DateTime checkDate = today.subtract(Duration(days: i));
      String dateKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      int dailyCount = _recentActivity
          .where((activity) => activity['date'] == dateKey)
          .length;

      if (dailyCount == 5) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak() {
    // This would be calculated from historical data
    // For now, return a value based on current streak + some bonus
    return _currentStreak + (_totalPrayers ~/ 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Prayer Statistics'),
      body: Column(
        children: [
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Prayers',
                    value: _totalPrayers.toString(),
                    icon: Icons.mosque,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Current Streak',
                    value: '$_currentStreak days',
                    icon: Icons.local_fire_department,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Progress'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                _ProgressTab(),
                _HistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _OverviewTab() {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Prayer Breakdown
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prayer Breakdown',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...prayers.map((prayer) {
                  int count = _prayerCounts[prayer] ?? 0;
                  double percentage = _totalPrayers > 0 ? (count / _totalPrayers) * 100 : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getPrayerIcon(prayer),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prayer, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              Text('$count prayers (${percentage.toStringAsFixed(1)}%)',
                                   style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Achievement Cards
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _AchievementItem(
                  icon: Icons.emoji_events,
                  title: 'Longest Streak',
                  description: '$_longestStreak consecutive days',
                  isUnlocked: _longestStreak > 0,
                ),
                _AchievementItem(
                  icon: Icons.star,
                  title: 'Prayer Warrior',
                  description: 'Complete 100 prayers',
                  isUnlocked: _totalPrayers >= 100,
                ),
                _AchievementItem(
                  icon: Icons.local_fire_department,
                  title: 'Consistent Believer',
                  description: 'Maintain 7-day streak',
                  isUnlocked: _currentStreak >= 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Monthly Progress
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month\'s Progress',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _MonthlyProgressChart(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weekly Goals
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Goals',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _GoalProgress(
                  title: 'Daily Prayers',
                  current: _currentStreak,
                  target: 7,
                  unit: 'days',
                ),
                _GoalProgress(
                  title: 'Total Prayers',
                  current: _totalPrayers % 35,
                  target: 35,
                  unit: 'prayers',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _HistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          if (_recentActivity.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No prayer history yet.\nStart tracking your prayers!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ..._recentActivity.reversed.take(20).map((activity) {
              return CustomCard(
                padding: const EdgeInsets.all(12),
                // margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPrayerIcon(activity['prayer']),
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['prayer'],
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${activity['date']} at ${activity['time']}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String prayer) {
    switch (prayer) {
      case 'Fajr': return Icons.wb_sunny_outlined;
      case 'Dhuhr': return Icons.wb_sunny;
      case 'Asr': return Icons.wb_cloudy;
      case 'Maghrib': return Icons.brightness_3;
      case 'Isha': return Icons.nightlight;
      default: return Icons.mosque;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
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
            style: AppTextStyles.heading2.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;

  const _AchievementItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? AppColors.accent : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

class _MonthlyProgressChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: const Center(
        child: Text(
          'Progress Chart\n(Visual chart would be implemented here)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final String title;
  final int current;
  final int target;
  final String unit;

  const _GoalProgress({
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    double progress = current / target;
    if (progress > 1) progress = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text('$current/$target $unit', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.textSecondary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }
}
