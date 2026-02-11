import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart';
import '../../quran_streak/providers/quran_streak_provider.dart';
import '../../reflections/providers/reflections_provider.dart';
import '../../ramadan_habits/providers/ramadan_habits_provider.dart';

class NoorWrapData {
  final int totalDhikrCount;
  final int totalPagesRead;
  final int quranStreakDays;
  final int totalReflections;
  final double avgSentiment;
  final int ramadanChallengesCompleted;
  final String topPrayer; // Most reflected-on prayer
  final int daysActive;

  const NoorWrapData({
    this.totalDhikrCount = 0,
    this.totalPagesRead = 0,
    this.quranStreakDays = 0,
    this.totalReflections = 0,
    this.avgSentiment = 0,
    this.ramadanChallengesCompleted = 0,
    this.topPrayer = '',
    this.daysActive = 0,
  });
}

class NoorWrapNotifier extends StateNotifier<NoorWrapData> {
  final Ref _ref;
  final SharedPreferences _prefs;

  NoorWrapNotifier(this._ref, this._prefs) : super(const NoorWrapData()) {
    _aggregateData();
  }

  void _aggregateData() {
    // Gather from all feature providers
    final streakState = _ref.read(quranStreakProvider);
    final reflState = _ref.read(reflectionsProvider);
    final ramadanState = _ref.read(ramadanHabitsProvider);

    // Dhikr count from prefs
    final dhikrCount = _prefs.getInt('total_dhikr_count') ?? 0;

    // Find top prayer from reflections
    String topPrayer = 'Fajr';
    if (reflState.prayerCounts.isNotEmpty) {
      topPrayer = reflState.prayerCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Days active (rough estimate from daily log)
    final daysActive = streakState.dailyLog.length;

    state = NoorWrapData(
      totalDhikrCount: dhikrCount,
      totalPagesRead: streakState.totalPagesRead,
      quranStreakDays: streakState.longestStreak,
      totalReflections: reflState.totalReflections,
      avgSentiment: reflState.averageSentiment,
      ramadanChallengesCompleted: ramadanState.completedCount,
      topPrayer: topPrayer,
      daysActive: daysActive,
    );
  }

  void refresh() => _aggregateData();
}

final noorWrapProvider = StateNotifierProvider<NoorWrapNotifier, NoorWrapData>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NoorWrapNotifier(ref, prefs);
});
