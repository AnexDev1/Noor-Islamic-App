import 'package:flutter/material.dart';
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
import '../../quran/ui/quran_hub_screen.dart';
import '../../hadith/ui/hadith_home_screen.dart';
import '../../azkhar/ui/azkhar_home_screen.dart';
import '../../tasbih/ui/tasbih_hub_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _countdownTimer;
  Duration _timeUntilNextPrayer = Duration.zero;
  final ValueNotifier<({String name, String time})> _countdown = ValueNotifier((
    name: '',
    time: '00:00:00',
  ));
  PrayerTimes? _currentPrayerTimes;

  @override
  void initState() {
    super.initState();
    // Update app usage when home screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userPreferencesProvider.notifier).updateLastAppUsage();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdown.dispose();
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
    });
  }

  void _updateCountdown() {
    if (_currentPrayerTimes == null) return;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final prayerNames = [
      l10n.fajr,
      l10n.dhuhr,
      l10n.asr,
      l10n.maghrib,
      l10n.isha,
    ];
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
    _countdown.value = (
      name: nextPrayerName,
      time: _formatDuration(_timeUntilNextPrayer),
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
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

                const SizedBox(height: 24), // Bottom spacing reduced
              ]),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with location
          Row(
            children: [
              Image.asset('assets/prayer.png', height: 21, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prayerTimes,
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    locationAsync.when(
                      loading: () => Text(
                        l10n.loading,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      error: (_, __) => Text(
                        l10n.error,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      data: (location) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${location.city}, ${location.country}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              height: 1.1,
                            ),
                          ),
                          if (prayerTimes.isUsingFallbackPrayerTimes)
                            Text(
                              l10n.usingDefaultTimes,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: () =>
                    ref.read(prayerTimesProvider.notifier).refreshPrayerTimes(),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Cool Next Prayer Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ValueListenableBuilder<({String name, String time})>(
              valueListenable: _countdown,
              builder: (context, countdown, _) => Row(
                children: [
                  // Next Prayer Icon
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Next Prayer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nextPrayer,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          countdown.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Countdown Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
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
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          countdown.time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
          ),

          const SizedBox(height: 6),

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

    return SizedBox(
      height: 48,
      child: Row(
        children: List.generate(prayers.length, (index) {
          final prayer = prayers[index];
          final isCompleted = todayStatus.dailyPrayers[prayer['key']] ?? false;

          return Expanded(
            child: GestureDetector(
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
                margin: EdgeInsets.only(
                  right: index == prayers.length - 1 ? 0 : 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 11,
                      ),
                    Flexible(
                      child: Text(
                        prayer['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      prayer['time']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
                                      greetingSnapshot.data ??
                                          AppLocalizations.of(
                                            context,
                                          )!.assalamuAlaikum,
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
                      _buildLanguageSwitcher(),
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

  Widget _buildLanguageSwitcher() {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String languageCode) {
        localeNotifier.setLocale(Locale(languageCode));
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: currentLocale.languageCode == 'en'
                    ? AppColors.primary
                    : Colors.transparent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'am',
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: currentLocale.languageCode == 'am'
                    ? AppColors.primary
                    : Colors.transparent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('አማርኛ'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'om',
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: currentLocale.languageCode == 'om'
                    ? AppColors.primary
                    : Colors.transparent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Afaan Oromoo'),
            ],
          ),
        ),
      ],
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
          MaterialPageRoute(builder: (_) => const QuranHubScreen()),
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
          MaterialPageRoute(builder: (_) => const TasbihHubScreen()),
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
              color: AppColors.primary.withValues(alpha: 0.3),
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
                            color: Colors.black.withValues(alpha: 0.15),
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
                                AppLocalizations.of(context)!.islamicVideos,
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
                            AppLocalizations.of(context)!.curatedIslamicContent,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
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
                      color: Colors.white.withValues(alpha: 0.7),
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
                            : Colors.white.withValues(alpha: 0.4),
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
