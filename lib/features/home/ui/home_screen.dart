import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../azkhar/ui/azkhar_home_screen.dart';
import '../../hadith/ui/hadith_home_screen.dart';
import '../../quran/ui/quran_hub_screen.dart';
import '../../tasbih/ui/tasbih_hub_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  PrayerTimes? _prayerTimes;
  final ValueNotifier<({String name, String time})> _countdown = ValueNotifier((
    name: '',
    time: '--:--:--',
  ));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userPreferencesProvider.notifier).updateLastAppUsage();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  void _connectCountdown(PrayerTimes times) {
    if (identical(_prayerTimes, times)) return;
    _prayerTimes = times;
    _updateCountdown();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final times = _prayerTimes;
    if (times == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final prayers = <(String, String)>[
      (l10n.fajr, times.fajr),
      (l10n.dhuhr, times.dhuhr),
      (l10n.asr, times.asr),
      (l10n.maghrib, times.maghrib),
      (l10n.isha, times.isha),
    ];
    var nextName = prayers.first.$1;
    DateTime? next;
    for (final prayer in prayers) {
      final parts = prayer.$2.split(':');
      if (parts.length < 2) continue;
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
      if (candidate.isAfter(now)) {
        next = candidate;
        nextName = prayer.$1;
        break;
      }
    }
    next ??= DateTime(
      now.year,
      now.month,
      now.day + 1,
      int.tryParse(prayers.first.$2.split(':').first) ?? 0,
      int.tryParse(prayers.first.$2.split(':').last) ?? 0,
    );
    final duration = next.difference(now);
    _countdown.value = (
      name: nextName,
      time:
          '${duration.inHours.toString().padLeft(2, '0')}:'
          '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
          '${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayers = ref.watch(prayerTimesProvider);
    final status = ref.watch(todayPrayerStatusProvider);
    final location = ref.watch(userLocationProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(prayerTimesProvider.notifier).refreshPrayerTimes(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _Header(onLanguageChanged: _setLocale)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              sliver: SliverList.list(
                children: [
                  prayers.when(
                    loading: _PrayerLoading.new,
                    error: (error, _) => _PrayerError(
                      onRetry: () => ref
                          .read(prayerTimesProvider.notifier)
                          .refreshPrayerTimes(),
                    ),
                    data: (times) {
                      _connectCountdown(times);
                      return _PrayerObservatory(
                        times: times,
                        status: status,
                        location: location,
                        countdown: _countdown,
                        onToggle: (key) => ref
                            .read(todayPrayerStatusProvider.notifier)
                            .togglePrayer(key),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _SectionHeading(
                    title: AppLocalizations.of(context)!.exploreNoor,
                    subtitle: AppLocalizations.of(context)!.discoverFeatures,
                  ),
                  const SizedBox(height: 16),
                  _FeatureGrid(items: _features(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setLocale(String code) =>
      ref.read(localeProvider.notifier).setLocale(Locale(code));

  List<_FeatureData> _features(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _FeatureData(
        l10n.quran,
        'Read & listen',
        Icons.auto_stories_rounded,
        AppColors.quranCard,
        const QuranHubScreen(),
      ),
      _FeatureData(
        l10n.azkhar,
        'Daily remembrance',
        Icons.wb_twilight_rounded,
        AppColors.azkharCard,
        const AzkharHomeScreen(),
      ),
      _FeatureData(
        l10n.hadith,
        'Prophetic guidance',
        Icons.format_quote_rounded,
        AppColors.hadithCard,
        const HadithHomeScreen(),
      ),
      _FeatureData(
        l10n.tasbih,
        'Keep your dhikr',
        Icons.blur_circular_rounded,
        AppColors.tasbihCard,
        const TasbihHubScreen(),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLanguageChanged});
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.nights_stay_rounded,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: FutureBuilder<String>(
              future: UserService.getUserName(),
              builder: (_, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.assalamuAlaikum,
                    style: const TextStyle(
                      color: Color(0xFFB8CAC8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snapshot.data ?? 'Abdullah',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Change language',
            onSelected: onLanguageChanged,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.translate_rounded, color: Colors.white),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'am', child: Text('አማርኛ')),
              PopupMenuItem(value: 'om', child: Text('Afaan Oromoo')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerObservatory extends StatelessWidget {
  const _PrayerObservatory({
    required this.times,
    required this.status,
    required this.location,
    required this.countdown,
    required this.onToggle,
  });
  final PrayerTimes times;
  final PrayerStatus status;
  final AsyncValue<UserLocation> location;
  final ValueNotifier<({String name, String time})> countdown;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(String, String, String)>[
      (l10n.fajr, times.fajr, 'Fajr'),
      (l10n.dhuhr, times.dhuhr, 'Dhuhr'),
      (l10n.asr, times.asr, 'Asr'),
      (l10n.maghrib, times.maghrib, 'Maghrib'),
      (l10n.isha, times.isha, 'Isha'),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _HorizonPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Color(0xFFB8CAC8),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location.when(
                                data: (place) =>
                                    '${place.city}, ${place.country}',
                                loading: () => l10n.loading,
                                error: (_, __) => l10n.prayerTimes,
                              ),
                              style: const TextStyle(
                                color: Color(0xFFB8CAC8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            l10n.prayerTimes,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ValueListenableBuilder<({String name, String time})>(
                        valueListenable: countdown,
                        builder: (_, value, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.nextPrayer} · ${value.name}',
                              style: const TextStyle(
                                color: Color(0xFFD5E1DF),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value.time,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              l10n.timeLeft,
                              style: const TextStyle(
                                color: Color(0xFF8FA8A6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            color: Colors.white.withValues(alpha: .055),
            child: Row(
              children: items.map((item) {
                final done = status.dailyPrayers[item.$3] ?? false;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: done,
                    label: '${item.$1}, ${item.$2}',
                    child: InkWell(
                      onTap: () => onToggle(item.$3),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 2,
                        ),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? AppColors.accent
                                    : const Color(0xFF587076),
                                boxShadow: done
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(
                                            alpha: .5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              item.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: done
                                    ? Colors.white
                                    : const Color(0xFFB8CAC8),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizonPainter extends CustomPainter {
  const _HorizonPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: .32),
              AppColors.accent.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .78, size.height * .2),
              radius: 92,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final arc = Paint()
      ..color = const Color(0xFF6E898C).withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * .12,
        size.height * .3,
        size.width * .92,
        size.height * .92,
      ),
      math.pi,
      math.pi,
      false,
      arc,
    );
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .2),
      5,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeatureData {
  const _FeatureData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.screen,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items});
  final List<_FeatureData> items;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.12,
    ),
    itemBuilder: (_, index) {
      final item = items[index];
      return Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFDCE6E3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.screen),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.heading1.copyWith(fontSize: 23)),
      const SizedBox(height: 4),
      Text(subtitle, style: AppTextStyles.bodyMedium),
    ],
  );
}

class _PrayerLoading extends StatelessWidget {
  const _PrayerLoading();
  @override
  Widget build(BuildContext context) => Container(
    height: 310,
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(26),
    ),
    child: const Center(
      child: CircularProgressIndicator(color: AppColors.accent),
    ),
  );
}

class _PrayerError extends StatelessWidget {
  const _PrayerError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 32),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context)!.error,
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context)!.retry),
        ),
      ],
    ),
  );
}
