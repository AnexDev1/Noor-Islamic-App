import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart'; // Import app_providers for localeProvider

// ═══════════════════════════════════════════════════════════════════
//  LEARN ISLAM — State management
// ═══════════════════════════════════════════════════════════════════

// ── Salah Steps Provider ────────────────────────────────────────

final salahStepsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final locale = ref.watch(localeProvider);
  String path = 'assets/data/salah_steps.json';

  if (locale.languageCode == 'am') {
    path = 'assets/data/salah_steps_am.json';
  } else if (locale.languageCode == 'om') {
    path = 'assets/data/salah_steps_om.json';
  }

  try {
    final jsonStr = await rootBundle.loadString(path);
    final list = jsonDecode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  } catch (e) {
    // Fallback to English if file missing or parse error
    final jsonStr = await rootBundle.loadString('assets/data/salah_steps.json');
    final list = jsonDecode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }
});

// ── Wudu Steps Provider ─────────────────────────────────────────

final wuduStepsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final locale = ref.watch(localeProvider);
  String path = 'assets/data/wudu_steps.json';

  if (locale.languageCode == 'am') {
    path = 'assets/data/wudu_steps_am.json';
  } else if (locale.languageCode == 'om') {
    path = 'assets/data/wudu_steps_om.json';
  }

  try {
    final jsonStr = await rootBundle.loadString(path);
    final list = jsonDecode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  } catch (e) {
    final jsonStr = await rootBundle.loadString('assets/data/wudu_steps.json');
    final list = jsonDecode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }
});

// ── Islamic Rules Provider ──────────────────────────────────────

final islamicRulesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final locale = ref.watch(localeProvider);
  String path = 'assets/data/islamic_rules.json';

  if (locale.languageCode == 'am') {
    path = 'assets/data/islamic_rules_am.json';
  } else if (locale.languageCode == 'om') {
    path = 'assets/data/islamic_rules_om.json';
  }

  try {
    final jsonStr = await rootBundle.loadString(path);
    final list = jsonDecode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  } catch (e) {
    final jsonStr = await rootBundle.loadString(
      'assets/data/islamic_rules.json',
    );
    final list = jsonDecode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }
});

// ── Progress Tracking ───────────────────────────────────────────

class LearnProgressState {
  final Set<int> completedSalahSteps;
  final Set<int> completedWuduSteps;
  final Set<String> completedRuleSections;
  final int quizScore;
  final int totalQuizAttempts;

  const LearnProgressState({
    this.completedSalahSteps = const {},
    this.completedWuduSteps = const {},
    this.completedRuleSections = const {},
    this.quizScore = 0,
    this.totalQuizAttempts = 0,
  });

  double get salahProgress =>
      completedSalahSteps.isEmpty ? 0.0 : completedSalahSteps.length / 10;
  double get wuduProgress =>
      completedWuduSteps.isEmpty ? 0.0 : completedWuduSteps.length / 10;

  LearnProgressState copyWith({
    Set<int>? completedSalahSteps,
    Set<int>? completedWuduSteps,
    Set<String>? completedRuleSections,
    int? quizScore,
    int? totalQuizAttempts,
  }) {
    return LearnProgressState(
      completedSalahSteps: completedSalahSteps ?? this.completedSalahSteps,
      completedWuduSteps: completedWuduSteps ?? this.completedWuduSteps,
      completedRuleSections:
          completedRuleSections ?? this.completedRuleSections,
      quizScore: quizScore ?? this.quizScore,
      totalQuizAttempts: totalQuizAttempts ?? this.totalQuizAttempts,
    );
  }
}

class LearnProgressNotifier extends StateNotifier<LearnProgressState> {
  LearnProgressNotifier() : super(const LearnProgressState()) {
    _loadProgress();
  }

  static const _keyPrefix = 'learn_islam_';

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final salahList = prefs.getStringList('${_keyPrefix}salah') ?? [];
    final wuduList = prefs.getStringList('${_keyPrefix}wudu') ?? [];
    final rulesList = prefs.getStringList('${_keyPrefix}rules') ?? [];
    final score = prefs.getInt('${_keyPrefix}quiz_score') ?? 0;
    final attempts = prefs.getInt('${_keyPrefix}quiz_attempts') ?? 0;

    state = state.copyWith(
      completedSalahSteps: salahList.map(int.parse).toSet(),
      completedWuduSteps: wuduList.map(int.parse).toSet(),
      completedRuleSections: rulesList.toSet(),
      quizScore: score,
      totalQuizAttempts: attempts,
    );
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '${_keyPrefix}salah',
      state.completedSalahSteps.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      '${_keyPrefix}wudu',
      state.completedWuduSteps.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      '${_keyPrefix}rules',
      state.completedRuleSections.toList(),
    );
    await prefs.setInt('${_keyPrefix}quiz_score', state.quizScore);
    await prefs.setInt('${_keyPrefix}quiz_attempts', state.totalQuizAttempts);
  }

  void completeSalahStep(int step) {
    final updated = {...state.completedSalahSteps, step};
    state = state.copyWith(completedSalahSteps: updated);
    _saveProgress();
  }

  void completeWuduStep(int step) {
    final updated = {...state.completedWuduSteps, step};
    state = state.copyWith(completedWuduSteps: updated);
    _saveProgress();
  }

  void completeRuleSection(String sectionId) {
    final updated = {...state.completedRuleSections, sectionId};
    state = state.copyWith(completedRuleSections: updated);
    _saveProgress();
  }

  void recordQuizResult(int correct, int total) {
    state = state.copyWith(
      quizScore: state.quizScore + correct,
      totalQuizAttempts: state.totalQuizAttempts + total,
    );
    _saveProgress();
  }

  void resetProgress() {
    state = const LearnProgressState();
    _saveProgress();
  }
}

final learnProgressProvider =
    StateNotifierProvider<LearnProgressNotifier, LearnProgressState>(
      (ref) => LearnProgressNotifier(),
    );

// ── Curated YouTube Video Data ──────────────────────────────────

class IslamicVideo {
  final String title;
  final String channelName;
  final String videoId;
  final String category;
  final String description;

  const IslamicVideo({
    required this.title,
    required this.channelName,
    required this.videoId,
    required this.category,
    required this.description,
  });
}

const List<IslamicVideo> kCuratedVideos = [
  IslamicVideo(
    title: 'How to Pray Step by Step',
    channelName: 'FreeQuranEducation',
    videoId: 'T4auGhmeBlw',
    category: 'Salah',
    description:
        'Complete guide on how to perform salah with all positions explained.',
  ),
  IslamicVideo(
    title: 'How to Perform Wudu',
    channelName: 'FreeQuranEducation',
    videoId: 'exQM0mSfC5I',
    category: 'Wudu',
    description: 'Step-by-step demonstration of the correct way to make wudu.',
  ),
  IslamicVideo(
    title: 'The Pillars of Islam',
    channelName: 'Yaqeen Institute',
    videoId: 'XjLHmPGfJBw',
    category: 'Basics',
    description:
        'Understanding the five pillars that form the foundation of Islam.',
  ),
  IslamicVideo(
    title: 'The Last Sermon of Prophet Muhammad ﷺ',
    channelName: 'Bayyinah Institute',
    videoId: '0cTg5D2sTrQ',
    category: 'Seerah',
    description: 'The final message of the Prophet ﷺ to humankind.',
  ),
  IslamicVideo(
    title: 'Understanding the Quran',
    channelName: 'Nouman Ali Khan',
    videoId: 'BaS5NsvZ4yM',
    category: 'Quran',
    description:
        'An introduction to understanding and connecting with the Quran.',
  ),
  IslamicVideo(
    title: 'What is Zakat',
    channelName: 'Yaqeen Institute',
    videoId: 'YFvJcSGRQ0M',
    category: 'Zakat',
    description: 'Comprehensive guide on how zakat works and who receives it.',
  ),
  IslamicVideo(
    title: 'Ramadan Guide for Beginners',
    channelName: 'FreeQuranEducation',
    videoId: 'wfXcLIzhKSQ',
    category: 'Fasting',
    description: 'Everything you need to know about fasting during Ramadan.',
  ),
  IslamicVideo(
    title: 'The Story of Prophet Ibrahim',
    channelName: 'FreeQuranEducation',
    videoId: 'XjLHmPGfJBw',
    category: 'Stories',
    description:
        'The inspiring story of Prophet Ibrahim and his unwavering faith.',
  ),
];

final videosCategoryProvider = StateProvider<String>((ref) => 'All');
