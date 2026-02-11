import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════
//  TASBIH HUB — Unified state management for all tasbih modes
// ═══════════════════════════════════════════════════════════════════

/// The three modes available in the Tasbih Hub.
enum TasbihMode { standard, nafasDhikr, beadFlow }

/// Each dhikr phrase with its metadata.
class DhikrPhrase {
  final String arabic;
  final String translation;
  final String meaning;
  final int defaultTarget;

  const DhikrPhrase({
    required this.arabic,
    required this.translation,
    required this.meaning,
    required this.defaultTarget,
  });
}

/// Universal set of dhikr phrases used across all modes.
const List<DhikrPhrase> kDhikrPhrases = [
  DhikrPhrase(
    arabic: 'سُبْحَانَ اللَّهِ',
    translation: 'Glory be to Allah',
    meaning: 'Praising Allah\'s perfection',
    defaultTarget: 33,
  ),
  DhikrPhrase(
    arabic: 'الْحَمْدُ لِلَّهِ',
    translation: 'Praise be to Allah',
    meaning: 'Thanking Allah for everything',
    defaultTarget: 33,
  ),
  DhikrPhrase(
    arabic: 'اللَّهُ أَكْبَرُ',
    translation: 'Allah is Greatest',
    meaning: 'Declaring Allah\'s greatness',
    defaultTarget: 34,
  ),
  DhikrPhrase(
    arabic: 'لَا إِلَهَ إِلَّا اللَّهُ',
    translation: 'There is no god but Allah',
    meaning: 'Declaration of faith',
    defaultTarget: 100,
  ),
  DhikrPhrase(
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    translation: 'I seek forgiveness from Allah',
    meaning: 'Seeking Allah\'s forgiveness',
    defaultTarget: 100,
  ),
];

/// Breath phase for Nafas mode.
enum BreathPhase { inhale, hold, exhale, rest }

// ─── State class ────────────────────────────────────────────────

class TasbihHubState {
  final TasbihMode mode;
  final int selectedPhraseIndex;
  final int count;
  final int target;
  final int totalLifetimeCount;
  final int streakDays;
  final DateTime? lastSessionDate;

  // Nafas-specific
  final bool isNafasActive;
  final BreathPhase breathPhase;
  final int nafasPhraseIndex; // auto-advances through first 3 phrases

  const TasbihHubState({
    this.mode = TasbihMode.standard,
    this.selectedPhraseIndex = 0,
    this.count = 0,
    this.target = 33,
    this.totalLifetimeCount = 0,
    this.streakDays = 0,
    this.lastSessionDate,
    this.isNafasActive = false,
    this.breathPhase = BreathPhase.inhale,
    this.nafasPhraseIndex = 0,
  });

  DhikrPhrase get currentPhrase => kDhikrPhrases[selectedPhraseIndex];

  double get progress => target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => count >= target;

  /// For nafas mode: the 3-phrase sequence (SubhanAllah, Alhamdulillah, Allahu Akbar)
  DhikrPhrase get nafasPhrase => kDhikrPhrases[nafasPhraseIndex];

  bool get isNafasAllComplete =>
      nafasPhraseIndex >= 2 && count >= kDhikrPhrases[2].defaultTarget;

  TasbihHubState copyWith({
    TasbihMode? mode,
    int? selectedPhraseIndex,
    int? count,
    int? target,
    int? totalLifetimeCount,
    int? streakDays,
    DateTime? lastSessionDate,
    bool? isNafasActive,
    BreathPhase? breathPhase,
    int? nafasPhraseIndex,
  }) {
    return TasbihHubState(
      mode: mode ?? this.mode,
      selectedPhraseIndex: selectedPhraseIndex ?? this.selectedPhraseIndex,
      count: count ?? this.count,
      target: target ?? this.target,
      totalLifetimeCount: totalLifetimeCount ?? this.totalLifetimeCount,
      streakDays: streakDays ?? this.streakDays,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      isNafasActive: isNafasActive ?? this.isNafasActive,
      breathPhase: breathPhase ?? this.breathPhase,
      nafasPhraseIndex: nafasPhraseIndex ?? this.nafasPhraseIndex,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────

class TasbihHubNotifier extends StateNotifier<TasbihHubState> {
  TasbihHubNotifier() : super(const TasbihHubState()) {
    _loadData();
  }

  // ── Persistence keys ──
  static const _kCount = 'tasbih_hub_count';
  static const _kTotal = 'tasbih_hub_total';
  static const _kPhrase = 'tasbih_hub_phrase';
  static const _kMode = 'tasbih_hub_mode';
  static const _kStreak = 'tasbih_hub_streak';
  static const _kLastSession = 'tasbih_hub_last_session';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kMode) ?? 0;
    final phraseIndex = prefs.getInt(_kPhrase) ?? 0;
    final count = prefs.getInt(_kCount) ?? 0;
    final total = prefs.getInt(_kTotal) ?? 0;
    final streak = prefs.getInt(_kStreak) ?? 0;
    final lastStr = prefs.getString(_kLastSession);

    state = state.copyWith(
      mode: TasbihMode.values[modeIndex.clamp(0, TasbihMode.values.length - 1)],
      selectedPhraseIndex: phraseIndex.clamp(0, kDhikrPhrases.length - 1),
      count: count,
      target: kDhikrPhrases[phraseIndex.clamp(0, kDhikrPhrases.length - 1)]
          .defaultTarget,
      totalLifetimeCount: total,
      streakDays: streak,
      lastSessionDate: lastStr != null ? DateTime.tryParse(lastStr) : null,
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMode, state.mode.index);
    await prefs.setInt(_kPhrase, state.selectedPhraseIndex);
    await prefs.setInt(_kCount, state.count);
    await prefs.setInt(_kTotal, state.totalLifetimeCount);
    await prefs.setInt(_kStreak, state.streakDays);
    if (state.lastSessionDate != null) {
      await prefs.setString(
        _kLastSession,
        state.lastSessionDate!.toIso8601String(),
      );
    }
  }

  // ── Mode switching ──
  void setMode(TasbihMode mode) {
    state = state.copyWith(mode: mode, count: 0);
    if (mode == TasbihMode.nafasDhikr) {
      state = state.copyWith(
        nafasPhraseIndex: 0,
        isNafasActive: true,
        target: kDhikrPhrases[0].defaultTarget,
      );
    }
    _saveData();
  }

  // ── Phrase selection (standard & bead modes) ──
  void selectPhrase(int index) {
    if (index < 0 || index >= kDhikrPhrases.length) return;
    state = state.copyWith(
      selectedPhraseIndex: index,
      count: 0,
      target: kDhikrPhrases[index].defaultTarget,
    );
    _saveData();
  }

  // ── Custom target ──
  void setTarget(int newTarget) {
    if (newTarget <= 0) return;
    state = state.copyWith(target: newTarget, count: 0);
    _saveData();
  }

  // ── Increment (shared by all modes) ──
  void increment() {
    final newCount = state.count + 1;
    final newTotal = state.totalLifetimeCount + 1;

    state = state.copyWith(count: newCount, totalLifetimeCount: newTotal);
    _updateStreak();
    _saveData();
  }

  // ── Nafas-specific: advance to next phrase automatically ──
  /// Returns true if all 3 phrases completed.
  bool nafasIncrement() {
    final newCount = state.count + 1;
    final newTotal = state.totalLifetimeCount + 1;
    final currentTarget = kDhikrPhrases[state.nafasPhraseIndex].defaultTarget;

    if (newCount >= currentTarget) {
      // Phrase done — move to next
      if (state.nafasPhraseIndex < 2) {
        final nextIdx = state.nafasPhraseIndex + 1;
        state = state.copyWith(
          count: 0,
          totalLifetimeCount: newTotal,
          nafasPhraseIndex: nextIdx,
          target: kDhikrPhrases[nextIdx].defaultTarget,
        );
        _updateStreak();
        _saveData();
        return false;
      } else {
        // All 3 done
        state = state.copyWith(
          count: newCount,
          totalLifetimeCount: newTotal,
          isNafasActive: false,
        );
        _updateStreak();
        _saveData();
        return true;
      }
    } else {
      state = state.copyWith(count: newCount, totalLifetimeCount: newTotal);
      _saveData();
      return false;
    }
  }

  // ── Reset current count ──
  void resetCount() {
    state = state.copyWith(count: 0);
    _saveData();
  }

  // ── Reset everything ──
  void resetAll() {
    state = state.copyWith(count: 0, totalLifetimeCount: 0);
    _saveData();
  }

  // ── Breath phase cycling (for Nafas mode UI) ──
  void setBreathPhase(BreathPhase phase) {
    state = state.copyWith(breathPhase: phase);
  }

  // ── Streak tracking ──
  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (state.lastSessionDate != null) {
      final lastDate = DateTime(
        state.lastSessionDate!.year,
        state.lastSessionDate!.month,
        state.lastSessionDate!.day,
      );
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        state = state.copyWith(
          streakDays: state.streakDays + 1,
          lastSessionDate: now,
        );
      } else if (diff > 1) {
        state = state.copyWith(streakDays: 1, lastSessionDate: now);
      } else {
        state = state.copyWith(lastSessionDate: now);
      }
    } else {
      state = state.copyWith(streakDays: 1, lastSessionDate: now);
    }
  }
}

// ─── Provider ───────────────────────────────────────────────────

final tasbihHubProvider =
    StateNotifierProvider<TasbihHubNotifier, TasbihHubState>(
      (ref) => TasbihHubNotifier(),
    );
