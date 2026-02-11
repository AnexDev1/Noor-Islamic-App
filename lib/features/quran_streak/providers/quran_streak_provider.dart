import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/providers/app_providers.dart';

class QuranStreakState {
  final int streakDays;
  final int longestStreak;
  final int totalPagesRead;
  final bool todayCompleted;
  final int mercyFreezeRemaining;
  final Map<String, int> dailyLog; // "yyyy-MM-dd" -> pages read
  final DateTime? lastReadDate;

  const QuranStreakState({
    this.streakDays = 0,
    this.longestStreak = 0,
    this.totalPagesRead = 0,
    this.todayCompleted = false,
    this.mercyFreezeRemaining = 1,
    this.dailyLog = const {},
    this.lastReadDate,
  });

  QuranStreakState copyWith({
    int? streakDays,
    int? longestStreak,
    int? totalPagesRead,
    bool? todayCompleted,
    int? mercyFreezeRemaining,
    Map<String, int>? dailyLog,
    DateTime? lastReadDate,
  }) {
    return QuranStreakState(
      streakDays: streakDays ?? this.streakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      mercyFreezeRemaining: mercyFreezeRemaining ?? this.mercyFreezeRemaining,
      dailyLog: dailyLog ?? this.dailyLog,
      lastReadDate: lastReadDate ?? this.lastReadDate,
    );
  }

  /// Get the status of the last N days for the garden display.
  List<GardenDayStatus> getGardenDays(int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <GardenDayStatus>[];
    for (int i = count - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = _dateKey(date);
      final pages = dailyLog[key] ?? 0;
      final isToday = i == 0;
      days.add(
        GardenDayStatus(
          date: date,
          pagesRead: pages,
          isToday: isToday,
          isCompleted: pages > 0,
        ),
      );
    }
    return days;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class GardenDayStatus {
  final DateTime date;
  final int pagesRead;
  final bool isToday;
  final bool isCompleted;

  const GardenDayStatus({
    required this.date,
    required this.pagesRead,
    required this.isToday,
    required this.isCompleted,
  });
}

class QuranStreakNotifier extends StateNotifier<QuranStreakState> {
  final SharedPreferences _prefs;

  QuranStreakNotifier(this._prefs) : super(const QuranStreakState()) {
    _loadData();
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _loadData() {
    final streak = _prefs.getInt('quran_streak') ?? 0;
    final longest = _prefs.getInt('quran_longest_streak') ?? 0;
    final total = _prefs.getInt('quran_total_pages') ?? 0;
    final mercy = _prefs.getInt('quran_mercy_freeze') ?? 1;
    final lastStr = _prefs.getString('quran_last_read');
    final lastDate = lastStr != null ? DateTime.tryParse(lastStr) : null;
    final logStr = _prefs.getString('quran_daily_log');
    final log = logStr != null
        ? Map<String, int>.from(jsonDecode(logStr))
        : <String, int>{};

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final todayDone = (log[todayKey] ?? 0) > 0;

    // Check if streak broke
    int actualStreak = streak;
    if (lastDate != null) {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(lastDay).inDays;
      if (diff > 2) actualStreak = 0; // Streak broken (beyond mercy freeze)
    }

    state = state.copyWith(
      streakDays: actualStreak,
      longestStreak: longest,
      totalPagesRead: total,
      todayCompleted: todayDone,
      mercyFreezeRemaining: mercy,
      dailyLog: log,
      lastReadDate: lastDate,
    );
  }

  Future<void> _saveData() async {
    await _prefs.setInt('quran_streak', state.streakDays);
    await _prefs.setInt('quran_longest_streak', state.longestStreak);
    await _prefs.setInt('quran_total_pages', state.totalPagesRead);
    await _prefs.setInt('quran_mercy_freeze', state.mercyFreezeRemaining);
    if (state.lastReadDate != null) {
      await _prefs.setString(
        'quran_last_read',
        state.lastReadDate!.toIso8601String(),
      );
    }
    await _prefs.setString('quran_daily_log', jsonEncode(state.dailyLog));
  }

  Future<void> logReading(int pages) async {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final today = DateTime(now.year, now.month, now.day);

    final newLog = Map<String, int>.from(state.dailyLog);
    newLog[todayKey] = (newLog[todayKey] ?? 0) + pages;

    int newStreak = state.streakDays;
    if (!state.todayCompleted) {
      // First read today
      if (state.lastReadDate != null) {
        final lastDay = DateTime(
          state.lastReadDate!.year,
          state.lastReadDate!.month,
          state.lastReadDate!.day,
        );
        final diff = today.difference(lastDay).inDays;
        if (diff <= 1) {
          newStreak++;
        } else {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
    }

    final newLongest = newStreak > state.longestStreak
        ? newStreak
        : state.longestStreak;

    // Reset mercy freeze weekly
    int newMercy = state.mercyFreezeRemaining;
    if (now.weekday == DateTime.monday && !state.todayCompleted) {
      newMercy = 1;
    }

    state = state.copyWith(
      dailyLog: newLog,
      todayCompleted: true,
      totalPagesRead: state.totalPagesRead + pages,
      streakDays: newStreak,
      longestStreak: newLongest,
      lastReadDate: now,
      mercyFreezeRemaining: newMercy,
    );
    await _saveData();
  }

  Future<void> useMercyFreeze() async {
    if (state.mercyFreezeRemaining > 0) {
      state = state.copyWith(
        mercyFreezeRemaining: state.mercyFreezeRemaining - 1,
        todayCompleted: true,
      );
      await _saveData();
    }
  }
}

final quranStreakProvider =
    StateNotifierProvider<QuranStreakNotifier, QuranStreakState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return QuranStreakNotifier(prefs);
    });
