import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/user_service.dart';
import '../../home/data/prayer_time_api.dart';
import '../../quran/ui/quran_screen.dart';
import '../../hadith/ui/hadith_home_screen.dart';
import '../../azkhar/ui/azkhar_home_screen.dart';
import '../../tasbih/ui/tasbih_screen.dart';
import '../../../core/utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, String>? _prayerTimes;
  bool _loading = true;
  String? _error;
  double? _lat;
  double? _lon;
  bool _usingFallbackLocation = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Prayer tracker state
  Map<String, bool> _prayerStatus = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCachedPrayerTimes();
    _loadPrayerStatus();
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
    super.dispose();
  }

  Future<void> _loadCachedPrayerTimes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final cachedTimes = prefs.getString('prayerTimes');
    final cachedLat = prefs.getDouble('lat');
    final cachedLon = prefs.getDouble('lon');

    if (cachedTimes != null && cachedLat != null && cachedLon != null) {
      setState(() {
        _prayerTimes = Map<String, String>.from(json.decode(cachedTimes));
        _lat = cachedLat;
        _lon = cachedLon;
        _loading = false;
      });
    } else {
      await _fetchPrayerTimesWithLocation();
    }
  }

  Future<void> _fetchPrayerTimesWithLocation() async {
    setState(() {
      _loading = true;
      _error = null;
      _usingFallbackLocation = false;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _lat = 21.4225;
        _lon = 39.8262;
        _usingFallbackLocation = true;
      } else {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _lat = position.latitude;
        _lon = position.longitude;
      }

      final times = await PrayerTimeApi.fetchPrayerTimes(lat: _lat, lon: _lon);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', _lat!);
      await prefs.setDouble('lon', _lon!);
      await prefs.setString('prayerTimes', json.encode(times));

      setState(() {
        _prayerTimes = times;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to fetch prayer times.';
        _loading = false;
      });
    }
  }

  Future<void> _loadPrayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date

    setState(() {
      _prayerStatus = {
        'Fajr': prefs.getBool('prayer_fajr_$today') ?? false,
        'Dhuhr': prefs.getBool('prayer_dhuhr_$today') ?? false,
        'Asr': prefs.getBool('prayer_asr_$today') ?? false,
        'Maghrib': prefs.getBool('prayer_maghrib_$today') ?? false,
        'Isha': prefs.getBool('prayer_isha_$today') ?? false,
      };
    });
  }

  Future<void> _savePrayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    await prefs.setBool('prayer_fajr_$today', _prayerStatus['Fajr']!);
    await prefs.setBool('prayer_dhuhr_$today', _prayerStatus['Dhuhr']!);
    await prefs.setBool('prayer_asr_$today', _prayerStatus['Asr']!);
    await prefs.setBool('prayer_maghrib_$today', _prayerStatus['Maghrib']!);
    await prefs.setBool('prayer_isha_$today', _prayerStatus['Isha']!);
  }

  @override
  Widget build(BuildContext context) {
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

                    // Inspirational Quote Section
                    _buildInspirationalSection(),

                    const SizedBox(height: 24),

                    // Next Prayer Card
                    _buildNextPrayerCard(),

                    const SizedBox(height: 32),

                    // Prayer Times Section
                    _buildPrayerTimesSection(),

                    const SizedBox(height: 32),

                    // Quick Actions Section
                    _buildQuickActionsSection(),

                    const SizedBox(height: 32),

                    // Islamic Features Grid
                    _buildFeaturesGrid(),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 28,
                        ),
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
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nameSnapshot.data ?? 'Abdullah',
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
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

  Widget _buildInspirationalSection() {
    final quotes = [
      {
        'text': 'And whoever relies upon Allah - then He is sufficient for him.',
        'source': 'Quran 65:3',
        'icon': Icons.auto_awesome,
      },
      {
        'text': 'Indeed, with hardship comes ease.',
        'source': 'Quran 94:6',
        'icon': Icons.wb_sunny,
      },
      {
        'text': 'And Allah is the best of planners.',
        'source': 'Quran 8:30',
        'icon': Icons.favorite,
      },
    ];

    final random = Random();
    final selectedQuote = quotes[random.nextInt(quotes.length)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.accentLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            selectedQuote['icon'] as IconData,
            size: 32,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            selectedQuote['text'] as String,
            textAlign: TextAlign.center,
            style: AppTextStyles.arabicMedium.copyWith(
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            selectedQuote['source'] as String,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    // Determine the next prayer time
    final now = DateTime.now();
    DateTime? nextPrayerTime;
    String? nextPrayerName;

    for (var entry in _prayerTimes!.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      final timeParts = prayerTime.split(':');
      final prayerDateTime = DateTime(now.year, now.month, now.day, int.parse(timeParts[0]), int.parse(timeParts[1]));

      if (prayerDateTime.isAfter(now)) {
        nextPrayerTime = prayerDateTime;
        nextPrayerName = prayerName;
        break;
      }
    }

    if (nextPrayerTime == null) {
      return Container(); // No upcoming prayer found
    }

    final isCompleted = _prayerStatus[nextPrayerName] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prayer info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Prayer',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nextPrayerName!,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.jm().format(nextPrayerTime),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Action button
          GestureDetector(
            onTap: () {
              // Mark as completed
              _togglePrayerCompletion(nextPrayerName!, !isCompleted);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                      : [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check : Icons.flag,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCompleted ? 'Completed' : 'Mark as Done',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prayer Times',
              style: AppTextStyles.heading1,
            ),
            if (_usingFallbackLocation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mecca',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          _buildPrayerTimesShimmer()
        else if (_error != null)
          _buildErrorCard()
        else
          _buildPrayerTimesCards(),
      ],
    );
  }

  Widget _buildPrayerTimesShimmer() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.surfaceVariant,
            highlightColor: AppColors.surface,
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesCards() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _prayerTimes!.entries.map((entry) {
          final name = entry.key;
          final time = entry.value;
          final isCompleted = _prayerStatus[name] ?? false;

          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: isCompleted ? Border.all(
                color: AppColors.success,
                width: 2,
              ) : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            _getPrayerIcon(name),
                            color: Colors.white,
                            size: 24,
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        name,
                        style: AppTextStyles.prayerName,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: AppTextStyles.prayerTime,
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return Icons.brightness_2;
      case 'Sunrise':
        return Icons.wb_sunny;
      case 'Dhuhr':
        return Icons.wb_sunny_outlined;
      case 'Asr':
        return Icons.brightness_6;
      case 'Maghrib':
        return Icons.brightness_4;
      case 'Isha':
        return Icons.bedtime;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prayer Tracker',
          style: AppTextStyles.heading1,
        ),
        const SizedBox(height: 16),
        _buildPrayerTracker(),
      ],
    );
  }

  Widget _buildPrayerTracker() {
    final completedCount = _prayerStatus.values.where((completed) => completed).length;
    final totalPrayers = _prayerStatus.length;
    final progress = completedCount / totalPrayers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header with progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Progress',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '$completedCount of $totalPrayers prayers completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: completedCount == totalPrayers
                        ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                        : [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completedCount == totalPrayers ? Icons.celebration : Icons.flag,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Prayer circles with long press
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _prayerStatus.entries.map((entry) {
              final prayerName = entry.key;
              final isCompleted = entry.value;
              final prayerTime = _prayerTimes?[prayerName] ?? '--';

              return GestureDetector(
                onLongPress: () {
                  _togglePrayerCompletion(prayerName, !isCompleted);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              )
                            : null,
                        color: isCompleted ? null : AppColors.textTertiary.withValues(alpha: 0.2),
                        border: !isCompleted ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 2,
                        ) : null,
                        boxShadow: isCompleted ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted ? Icons.check : _getPrayerIcon(prayerName),
                          color: isCompleted ? Colors.white : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prayerName,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isCompleted ? AppColors.primary : AppColors.textTertiary,
                        fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      prayerTime,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Progress bar
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: completedCount == totalPrayers
                        ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                        : [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: (completedCount == totalPrayers ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Motivational message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: completedCount == totalPrayers
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: completedCount == totalPrayers
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  completedCount == totalPrayers ? Icons.emoji_events : Icons.schedule,
                  color: completedCount == totalPrayers ? AppColors.success : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    completedCount == totalPrayers
                        ? 'Alhamdulillah! All prayers completed today! 🎉'
                        : completedCount > 0
                            ? 'MashAllah! ${totalPrayers - completedCount} prayers remaining'
                            : 'Long press prayer circles to mark as completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: completedCount == totalPrayers ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePrayerCompletion(String prayerName, bool isCompleted) async {
    // Update state immediately for instant feedback
    setState(() {
      _prayerStatus[prayerName] = isCompleted;
    });

    // Save to SharedPreferences
    await _savePrayerStatus();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Show feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.remove_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCompleted
                    ? 'Alhamdulillah! $prayerName prayer completed'
                    : '$prayerName prayer unmarked',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isCompleted ? AppColors.success : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'title': 'Holy Quran',
        'subtitle': 'Read & Listen',
        'icon': '📖',
        'gradient': [AppColors.primary, AppColors.primaryLight],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen())),
      },
      {
        'title': 'Hadith',
        'subtitle': 'Prophet\'s Sayings',
        'icon': '📚',
        'gradient': [AppColors.success, AppColors.success],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithHomeScreen())),
      },
      {
        'title': 'Azkar',
        'subtitle': 'Daily Remembrance',
        'icon': '🤲',
        'gradient': [AppColors.accent, AppColors.accentLight],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkharHomeScreen())),
      },
      {
        'title': 'Tasbih',
        'subtitle': 'Digital Counter',
        'icon': '📿',
        'gradient': [AppColors.warning, AppColors.warning],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen())),
      },
      {
        'title': 'Qibla',
        'subtitle': 'Direction Finder',
        'icon': '🧭',
        'gradient': [AppColors.secondary, AppColors.secondaryLight],
        'onTap': () => AppHelpers.showSnackBar(context, 'Qibla feature coming soon!'),
      },
      {
        'title': 'Donate',
        'subtitle': 'Help Others',
        'icon': '💝',
        'gradient': [AppColors.primary, AppColors.primaryLight],
        'onTap': () => AppHelpers.showSnackBar(context, 'Donation feature coming soon!'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Islamic Features',
          style: AppTextStyles.heading1,
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];

            return GestureDetector(
              onTap: feature['onTap'] as VoidCallback,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: feature['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (feature['gradient'] as List<Color>)[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            feature['icon'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Title and subtitle
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
