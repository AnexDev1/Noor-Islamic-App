import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart';

// ── Dhikr session data ──

class DhikrPhrase {
  final String arabic;
  final String transliteration;
  final String translation;
  final int target;

  const DhikrPhrase({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.target,
  });
}

enum BreathPhase { inhale, hold, exhale }

class DhikrSessionState {
  final int currentPhraseIndex;
  final int count;
  final bool isActive;
  final BreathPhase breathPhase;
  final int streakDays;
  final DateTime? lastSessionDate;
  final int totalLifetimeCount;

  const DhikrSessionState({
    this.currentPhraseIndex = 0,
    this.count = 0,
    this.isActive = false,
    this.breathPhase = BreathPhase.inhale,
    this.streakDays = 0,
    this.lastSessionDate,
    this.totalLifetimeCount = 0,
  });

  static const phrases = [
    DhikrPhrase(
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'SubhanAllah',
      translation: 'Glory be to Allah',
      target: 33,
    ),
    DhikrPhrase(
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      translation: 'Praise be to Allah',
      target: 33,
    ),
    DhikrPhrase(
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      target: 34,
    ),
  ];

  DhikrPhrase get currentPhrase => phrases[currentPhraseIndex];
  bool get isSetComplete => count >= currentPhrase.target;
  bool get isAllComplete =>
      currentPhraseIndex >= phrases.length - 1 && isSetComplete;
  double get progress =>
      currentPhrase.target > 0 ? count / currentPhrase.target : 0;

  DhikrSessionState copyWith({
    int? currentPhraseIndex,
    int? count,
    bool? isActive,
    BreathPhase? breathPhase,
    int? streakDays,
    DateTime? lastSessionDate,
    int? totalLifetimeCount,
  }) {
    return DhikrSessionState(
      currentPhraseIndex: currentPhraseIndex ?? this.currentPhraseIndex,
      count: count ?? this.count,
      isActive: isActive ?? this.isActive,
      breathPhase: breathPhase ?? this.breathPhase,
      streakDays: streakDays ?? this.streakDays,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      totalLifetimeCount: totalLifetimeCount ?? this.totalLifetimeCount,
    );
  }
}

class DhikrSessionNotifier extends StateNotifier<DhikrSessionState> {
  final SharedPreferences _prefs;

  DhikrSessionNotifier(this._prefs) : super(const DhikrSessionState()) {
    _loadData();
  }

  void _loadData() {
    final streak = _prefs.getInt('dhikr_streak') ?? 0;
    final total = _prefs.getInt('dhikr_total_count') ?? 0;
    final lastStr = _prefs.getString('dhikr_last_session');
    final lastDate = lastStr != null ? DateTime.tryParse(lastStr) : null;

    state = state.copyWith(
      streakDays: streak,
      totalLifetimeCount: total,
      lastSessionDate: lastDate,
    );
  }

  Future<void> _saveData() async {
    await _prefs.setInt('dhikr_streak', state.streakDays);
    await _prefs.setInt('dhikr_total_count', state.totalLifetimeCount);
    if (state.lastSessionDate != null) {
      await _prefs.setString(
        'dhikr_last_session',
        state.lastSessionDate!.toIso8601String(),
      );
    }
  }

  void startSession() {
    state = state.copyWith(isActive: true, count: 0, currentPhraseIndex: 0);
  }

  void incrementCount() {
    final newCount = state.count + 1;
    final newTotal = state.totalLifetimeCount + 1;

    if (newCount >= state.currentPhrase.target) {
      // Set complete
      if (state.currentPhraseIndex < DhikrSessionState.phrases.length - 1) {
        // Move to next phrase
        state = state.copyWith(
          count: 0,
          currentPhraseIndex: state.currentPhraseIndex + 1,
          totalLifetimeCount: newTotal,
        );
      } else {
        // All phrases complete
        _completeSession(newTotal);
      }
    } else {
      state = state.copyWith(count: newCount, totalLifetimeCount: newTotal);
    }
    _saveData();
  }

  void _completeSession(int newTotal) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = state.streakDays;

    if (state.lastSessionDate != null) {
      final lastDay = DateTime(
        state.lastSessionDate!.year,
        state.lastSessionDate!.month,
        state.lastSessionDate!.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    state = state.copyWith(
      isActive: false,
      totalLifetimeCount: newTotal,
      streakDays: newStreak,
      lastSessionDate: now,
    );
    _saveData();
  }

  void setBreathPhase(BreathPhase phase) {
    state = state.copyWith(breathPhase: phase);
  }

  void endSession() {
    state = state.copyWith(isActive: false);
  }
}

final dhikrSessionProvider =
    StateNotifierProvider<DhikrSessionNotifier, DhikrSessionState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return DhikrSessionNotifier(prefs);
    });
