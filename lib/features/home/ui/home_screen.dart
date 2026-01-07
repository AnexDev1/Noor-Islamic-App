import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/user_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import '../../quran/ui/quran_screen.dart';
import '../../hadith/ui/hadith_home_screen.dart';
import '../../azkhar/ui/azkhar_home_screen.dart';
import '../../tasbih/ui/tasbih_screen.dart';
import '../../videos/ui/video_hub_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

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
    final l10n = AppLocalizations.of(context)!;

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
                    _buildPrayerTimesCard(
                      prayerTimesAsync,
                      todayPrayerStatus,
                      locationAsync,
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions Grid
                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 24),

                    // Featured Videos Card
                    _buildFeaturedVideosCard(),

                    const SizedBox(height: 24), // Bottom spacing reduced
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedVideosCard() {
    return _IslamicVideosCarousel(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VideoHubScreen(
              channelIds: [
                // Verified Islamic Content Channel IDs Only
                'UCTX8ZbNDi_HBoyjTWRw9fAg',
                'UCNHaE-HxyC7PMqB-7QJEScg',
                'UCQQWZ1IeswjheSTSEXKcQsA',
                'UCNB_OaI4524fASt8h0IL8dw',
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimesCard(
    AsyncValue<PrayerTimes> prayerTimesAsync,
    PrayerStatus todayStatus,
    AsyncValue<UserLocation> locationAsync,
  ) {
    return prayerTimesAsync.when(
      loading: () => _buildLoadingPrayerCard(),
      error: (error, stack) => _buildErrorPrayerCard(error.toString()),
      data: (prayerTimes) {
        _startCountdown(prayerTimes);
        return _buildPrayerTimesContent(
          prayerTimes,
          todayStatus,
          locationAsync,
        );
      },
    );
  }

  Widget _buildLoadingPrayerCard() {
    return Container(
      height: 140,
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
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.loading,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPrayerCard(String error) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 140,
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
            const Icon(Icons.error_outline, color: Colors.white, size: 44),
            const SizedBox(height: 10),
            Text(
              l10n.error,
              style: AppTextStyles.heading3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                error,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.read(prayerTimesProvider.notifier).refreshPrayerTimes(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesContent(
    PrayerTimes prayerTimes,
    PrayerStatus todayStatus,
    AsyncValue<UserLocation> locationAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
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
                      l10n.prayerTimes,
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    locationAsync.when(
                      loading: () => Text(
                        l10n.loading,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      error: (_, __) => Text(
                        l10n.error,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      data: (location) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${location.city}, ${location.country}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (prayerTimes.isUsingFallbackPrayerTimes)
                            Text(
                              l10n.usingDefaultTimes,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(prayerTimesProvider.notifier).refreshPrayerTimes(),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cool Next Prayer Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Next Prayer Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Next Prayer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.nextPrayer,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nextPrayerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Countdown Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.timeLeft,
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
                          fontSize: 14,
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

          const SizedBox(height: 12),

          // Prayer times grid
          _buildPrayerTimesGrid(prayerTimes, todayStatus),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesGrid(
    PrayerTimes prayerTimes,
    PrayerStatus todayStatus,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final prayers = [
      {'name': l10n.fajr, 'time': prayerTimes.fajr, 'key': 'Fajr'},
      {'name': l10n.dhuhr, 'time': prayerTimes.dhuhr, 'key': 'Dhuhr'},
      {'name': l10n.asr, 'time': prayerTimes.asr, 'key': 'Asr'},
      {'name': l10n.maghrib, 'time': prayerTimes.maghrib, 'key': 'Maghrib'},
      {'name': l10n.isha, 'time': prayerTimes.isha, 'key': 'Isha'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        // Slightly taller tiles to prevent overflow when icons/borders appear
        childAspectRatio: 0.85,
      ),
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final isCompleted = todayStatus.dailyPrayers[prayer['key']] ?? false;

        return GestureDetector(
          onTap: () async {
            if (isCompleted) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.undoPrayerConfirmationTitle),
                  content: Text(l10n.undoPrayerConfirmationDesc),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.undo),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                ref
                    .read(todayPrayerStatusProvider.notifier)
                    .togglePrayer(prayer['key']!);
              }
            } else {
              ref
                  .read(todayPrayerStatusProvider.notifier)
                  .togglePrayer(prayer['key']!);
            }
          },
          child: Container(
            // slightly larger margin and consistent thin border to avoid layout jumps
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted ? Colors.green : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                Flexible(
                  child: Text(
                    prayer['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  prayer['time']!,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        );
      },
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
                                      greetingSnapshot.data ??
                                          'As-salamu Alaykum',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withAlpha(230),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nameSnapshot.data ?? 'User',
                                      style: AppTextStyles.displaySmall
                                          .copyWith(
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
    final l10n = AppLocalizations.of(context)!;
    final features = [
      {
        'title': l10n.quran,
        'icon': 'assets/quran.png',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuranScreen()),
        ),
      },
      {
        'title': l10n.hadith,
        'icon': Icons.format_quote_outlined,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HadithHomeScreen()),
        ),
      },
      {
        'title': l10n.azkhar,
        'icon': 'assets/azkhar.png',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AzkharHomeScreen()),
        ),
      },
      {
        'title': l10n.tasbih,
        'icon': 'assets/tasbih.png',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasbihScreen()),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.exploreNoor, style: AppTextStyles.heading1),
        const SizedBox(height: 8),
        Text(
          l10n.discoverFeatures,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
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
                          ? Image.asset(
                              feature['icon'] as String,
                              height: 32,
                              color: Colors.white,
                            )
                          : Icon(
                              feature['icon'] as IconData,
                              color: Colors.white,
                              size: 32,
                            ),
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

// Auto-Sliding Islamic Videos Carousel Widget
class _IslamicVideosCarousel extends StatefulWidget {
  final VoidCallback onTap;

  const _IslamicVideosCarousel({required this.onTap});

  @override
  State<_IslamicVideosCarousel> createState() => _IslamicVideosCarouselState();
}

class _IslamicVideosCarouselState extends State<_IslamicVideosCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  // Islamic-themed images - using network images for beautiful Islamic content
  final List<String> _images = [
    'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=800&q=80', // Kaaba
    'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=800&q=80', // Mosque dome
    'https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=800&q=80', // Quran
    'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=800&q=80', // Prayer beads
    'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=800&q=80', // Islamic calligraphy
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 100, // Reduced from 120 to 100
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(16), // Reduced border radius
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12, // Reduced blur
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Decorative pattern overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(painter: _IslamicPatternPainter()),
                ),
              ),

              // Sliding images as background (subtle)
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Opacity(
                      opacity: 0.15,
                      child: Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ), // Reduced padding
                child: Row(
                  children: [
                    // Play button - smaller
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 24, // Reduced size
                      ),
                    ),

                    const SizedBox(width: 12), // Reduced spacing
                    // Text content - simplified
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.video_library_rounded,
                                color: Colors.white,
                                size: 16, // Smaller icon
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Islamic Videos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16, // Smaller font
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2), // Reduced spacing
                          Text(
                            'Curated Islamic content & reminders',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11, // Smaller font
                              height: 1.2,
                            ),
                            maxLines: 1, // Single line only
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Arrow indicator
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Page indicators - smaller and repositioned
              Positioned(
                bottom: 8,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _images.length,
                    (dotIndex) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: _currentPage == dotIndex ? 12 : 4, // Smaller dots
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage == dotIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for Islamic pattern
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw subtle geometric Islamic patterns
    final spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 8, paint);
        canvas.drawLine(Offset(x - 8, y), Offset(x + 8, y), paint);
        canvas.drawLine(Offset(x, y - 8), Offset(x, y + 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
