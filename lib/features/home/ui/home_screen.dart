import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/user_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import '../../quran/ui/quran_screen.dart';
import '../../hadith/ui/hadith_home_screen.dart';
import '../../azkhar/ui/azkhar_home_screen.dart';
import '../../tasbih/ui/tasbih_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _countdownTimer;
  Duration _timeUntilNextPrayer = Duration.zero;
  String _countdownText = '';
  String _nextPrayerName = '';
  PrayerTimes? _currentPrayerTimes;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Update app usage when home screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userPreferencesProvider.notifier).updateLastAppUsage();
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(PrayerTimes prayerTimes) {
    _currentPrayerTimes = prayerTimes;
    _updateCountdown();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
      if (_timeUntilNextPrayer.inSeconds <= 0) {
        _countdownTimer?.cancel();
      }
      setState(() {});
    });
  }

  void _updateCountdown() {
    if (_currentPrayerTimes == null) return;
    final now = DateTime.now();
    final prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prayerTimesList = [
      _parsePrayerTime(_currentPrayerTimes!.fajr),
      _parsePrayerTime(_currentPrayerTimes!.dhuhr),
      _parsePrayerTime(_currentPrayerTimes!.asr),
      _parsePrayerTime(_currentPrayerTimes!.maghrib),
      _parsePrayerTime(_currentPrayerTimes!.isha),
    ];
    DateTime? nextPrayer;
    String nextPrayerName = '';
    for (int i = 0; i < prayerTimesList.length; i++) {
      if (prayerTimesList[i].isAfter(now)) {
        nextPrayer = prayerTimesList[i];
        nextPrayerName = prayerNames[i];
        break;
      }
    }
    if (nextPrayer == null) {
      // If all prayers passed, show until Fajr tomorrow
      nextPrayer = prayerTimesList[0].add(const Duration(days: 1));
      nextPrayerName = prayerNames[0];
    }
    _timeUntilNextPrayer = nextPrayer.difference(now);
    _countdownText = _formatDuration(_timeUntilNextPrayer);
    _nextPrayerName = nextPrayerName;
  }

  DateTime _parsePrayerTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Watch all the providers we need
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final todayPrayerStatus = ref.watch(todayPrayerStatusProvider);
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern App Bar with Profile Header
              _buildModernAppBar(context),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),

                    // Prayer Times Card
                    _buildPrayerTimesCard(prayerTimesAsync, todayPrayerStatus, locationAsync),

                    const SizedBox(height: 24),

                    // Today's Prayer Progress
                    _buildPrayerProgressCard(todayPrayerStatus),

                    const SizedBox(height: 24),

                    // Quick Actions Grid
                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 100), // Bottom spacing
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesCard(AsyncValue<PrayerTimes> prayerTimesAsync, PrayerStatus todayStatus, AsyncValue<UserLocation> locationAsync) {
    return prayerTimesAsync.when(
      loading: () => _buildLoadingPrayerCard(),
      error: (error, stack) => _buildErrorPrayerCard(error.toString()),
      data: (prayerTimes) {
        _startCountdown(prayerTimes);
        return _buildPrayerTimesContent(prayerTimes, todayStatus, locationAsync);
      },
    );
  }

  Widget _buildLoadingPrayerCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.7),
        child: const Center(
          child: Text(
            'Loading Prayer Times...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPrayerCard(String error) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.error.withValues(alpha: 0.8), AppColors.error],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading prayer times',
              style: AppTextStyles.heading3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(prayerTimesProvider.notifier).refreshPrayerTimes(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesContent(PrayerTimes prayerTimes, PrayerStatus todayStatus, AsyncValue<UserLocation> locationAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with location
          Row(
            children: [
              Image.asset('assets/prayer.png', height: 28, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Times',
                      style: AppTextStyles.heading2.copyWith(color: Colors.white),
                    ),
                    locationAsync.when(
                      loading: () => const Text('Loading location...', style: TextStyle(color: Colors.white70)),
                      error: (_, __) => const Text('Location unavailable', style: TextStyle(color: Colors.white70)),
                      data: (location) => Text(
                        '${location.city}, ${location.country}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.read(prayerTimesProvider.notifier).refreshPrayerTimes(),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Cool Next Prayer Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Next Prayer Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Next Prayer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Prayer',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nextPrayerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Countdown Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Time Left',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _countdownText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Prayer times grid
          _buildPrayerTimesGrid(prayerTimes, todayStatus),
        ],
      ),
    );
  }
  Widget _buildPrayerTimesGrid(PrayerTimes prayerTimes, PrayerStatus todayStatus) {
    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
      {'name': 'Asr', 'time': prayerTimes.asr},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib},
      {'name': 'Isha', 'time': prayerTimes.isha},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final isCompleted = todayStatus.dailyPrayers[prayer['name']] ?? false;

        return GestureDetector(
          onTap: () => ref.read(todayPrayerStatusProvider.notifier).togglePrayer(prayer['name']!),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: isCompleted ? Border.all(color: Colors.green, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                Text(
                  prayer['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prayer['time']!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerProgressCard(PrayerStatus todayStatus) {
    final completedPrayers = todayStatus.completedPrayers;
    final progress = completedPrayers / 5.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/today-progress.png', height: 24, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Today\'s Progress',
                  style: AppTextStyles.heading3,
                ),
              ),
              Text(
                '$completedPrayers/5',
                style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            completedPrayers == 5
              ? '🎉 Alhamdulillah! All prayers completed today!'
              : completedPrayers == 0
                ? 'Start your day with prayer'
                : 'Keep going! ${5 - completedPrayers} prayers remaining',
            style: AppTextStyles.body1.copyWith(
              color: completedPrayers == 5 ? Colors.green : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      FutureBuilder<String>(
                        future: UserService.getUserGender(),
                        builder: (context, genderSnapshot) {
                          final gender = genderSnapshot.data ?? 'male';
                          final asset = gender == 'female'
                              ? 'assets/female.png'
                              : 'assets/male.png';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(38),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(51),
                                width: 1,
                              ),
                            ),
                            child: Image.asset(
                              asset,
                              height: 28,
                              width: 28,
                              color: Colors.white,
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
                                        color: Colors.white.withAlpha(230),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nameSnapshot.data ?? 'User',
                                      style: AppTextStyles.displaySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final features = [
      {
        'title': 'Quran',
        'icon': 'assets/quran.png',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen())),
      },
      {
        'title': 'Hadith',
        'icon': Icons.format_quote_outlined,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithHomeScreen())),
      },
      {
        'title': 'Azkhar',
        'icon': 'assets/azkhar.png',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkharHomeScreen())),
      },
      {
        'title': 'Tasbih',
        'icon': 'assets/tasbih.png',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen())),
      },

    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Noor',
          style: AppTextStyles.heading1,
        ),
        const SizedBox(height: 8),
        Text(
          'Discover all the features of the app',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: features.map((feature) {
            return StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: GestureDetector(
                onTap: feature['onTap'] as void Function(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withAlpha(204),
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(77),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      feature['icon'] is String
                        ? Image.asset(feature['icon'] as String, height: 32, color: Colors.white)
                        : Icon(feature['icon'] as IconData, color: Colors.white, size: 32),
                      Text(
                        feature['title'] as String,
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
