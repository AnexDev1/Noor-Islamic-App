import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import 'dart:math' as math;

class PrayerStatsScreen extends ConsumerStatefulWidget {
  const PrayerStatsScreen({super.key});

  @override
  ConsumerState<PrayerStatsScreen> createState() => _PrayerStatsScreenState();
}

class _PrayerStatsScreenState extends ConsumerState<PrayerStatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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

  @override
  Widget build(BuildContext context) {
    final prayerStats = ref.watch(prayerStatsProvider);
    final todayStatus = ref.watch(todayPrayerStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Hero Stats Section
              SliverToBoxAdapter(
                child: _buildHeroSection(prayerStats, todayStatus),
              ),

              // Quick Overview Cards
              SliverToBoxAdapter(
                child: _buildQuickOverview(prayerStats, todayStatus),
              ),

              // Prayer Breakdown
              SliverToBoxAdapter(
                child: _buildPrayerBreakdown(prayerStats),
              ),

              // Recent Activity
              SliverToBoxAdapter(
                child: _buildRecentActivity(prayerStats),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Prayer Statistics',
        style: AppTextStyles.heading2.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () => ref.read(prayerStatsProvider.notifier).refreshStats(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(13), // 0.05 opacity
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(PrayerStats stats, PrayerStatus todayStatus) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77), // 0.3 opacity
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${todayStatus.completedPrayers}/5',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 48,
                      ),
                    ),
                    Text(
                      'Prayers Completed',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCircularProgress(
                todayStatus.completedPrayers / 5,
                Colors.white,
                Colors.white.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStreakBadge(stats.currentStreak),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(double progress, Color activeColor, Color backgroundColor) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mosque_outlined,
              color: activeColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Color(0xFFFF6B35),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$streak Day Streak',
            style: AppTextStyles.body1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOverview(PrayerStats stats, PrayerStatus todayStatus) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Total Prayers',
              '${stats.totalPrayers}',
              Icons.assessment_outlined,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Weekly Rate',
              '${stats.weeklyCompletionRate.toStringAsFixed(0)}%',
              Icons.trending_up_outlined,
              const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Best Streak',
              '${stats.longestStreak}d',
              Icons.emoji_events_outlined,
              const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: const Color(0xFF1A202C),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerBreakdown(PrayerStats stats) {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final colors = [
      AppColors.fajr,
      AppColors.dhuhr,
      AppColors.asr,
      AppColors.maghrib,
      AppColors.isha,
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(13), // 0.05 opacity
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prayer Breakdown',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...prayers.asMap().entries.map((entry) {
            final index = entry.key;
            final prayer = entry.value;
            final count = stats.prayerCounts[prayer] ?? 0;
            final maxCount = stats.prayerCounts.values.fold(0, math.max);
            final percentage = maxCount > 0 ? count / maxCount : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors[index].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        prayer[0],
                        style: AppTextStyles.body1.copyWith(
                          color: colors[index],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              prayer,
                              style: AppTextStyles.body1.copyWith(
                                color: const Color(0xFF1A202C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$count',
                              style: AppTextStyles.body1.copyWith(
                                color: colors[index],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: colors[index].withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(colors[index]),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(PrayerStats stats) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(13), // 0.05 opacity
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...stats.recentActivity.take(7).map((activity) {
            final isComplete = activity.completedPrayers == 5;
            final completionRate = activity.completedPrayers / 5;
            final now = DateTime(2025, 9, 21);
            final diff = now.difference(activity.date).inDays;
            String dateLabel;
            if (diff == 0) {
              dateLabel = 'Today';
            } else if (diff == 1) {
              dateLabel = 'Yesterday';
            } else if (diff > 1 && diff <= 4) {
              dateLabel = '$diff days ago';
            } else {
              dateLabel = '${activity.date.day}/${activity.date.month}/${activity.date.year}';
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: isComplete
                    ? Border.all(color: AppColors.success.withAlpha(77))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success.withAlpha(25)
                          : AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isComplete ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                      color: isComplete ? AppColors.success : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: completionRate,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? AppColors.success : AppColors.primary,
                          ),
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success.withAlpha(25)
                          : AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${activity.completedPrayers}/5',
                      style: AppTextStyles.caption.copyWith(
                        color: isComplete ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
