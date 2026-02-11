import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart';

class RamadanChallenge {
  final int id;
  final String titleEn;
  final String titleAr;
  final String icon;
  final String category;
  final bool isCompleted;

  const RamadanChallenge({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.icon,
    required this.category,
    this.isCompleted = false,
  });

  RamadanChallenge copyWith({bool? isCompleted}) => RamadanChallenge(
    id: id,
    titleEn: titleEn,
    titleAr: titleAr,
    icon: icon,
    category: category,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

class RamadanHabitsState {
  final List<RamadanChallenge> challenges;
  final int completedCount;
  final bool isLoading;
  final double progressPercent;

  const RamadanHabitsState({
    this.challenges = const [],
    this.completedCount = 0,
    this.isLoading = true,
    this.progressPercent = 0,
  });

  RamadanHabitsState copyWith({
    List<RamadanChallenge>? challenges,
    int? completedCount,
    bool? isLoading,
    double? progressPercent,
  }) {
    return RamadanHabitsState(
      challenges: challenges ?? this.challenges,
      completedCount: completedCount ?? this.completedCount,
      isLoading: isLoading ?? this.isLoading,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}

class RamadanHabitsNotifier extends StateNotifier<RamadanHabitsState> {
  final SharedPreferences _prefs;

  RamadanHabitsNotifier(this._prefs) : super(const RamadanHabitsState()) {
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/ramadan_challenges.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      // Load completed map
      final completedStr = _prefs.getString('ramadan_completed') ?? '{}';
      final Map<String, dynamic> completedMap = jsonDecode(completedStr);

      final challenges = jsonList.map((j) {
        final id = j['id'] as int;
        return RamadanChallenge(
          id: id,
          titleEn: j['title_en'],
          titleAr: j['title_ar'],
          icon: j['icon'],
          category: j['category'],
          isCompleted: completedMap[id.toString()] == true,
        );
      }).toList();

      final completed = challenges.where((c) => c.isCompleted).length;

      state = state.copyWith(
        challenges: challenges,
        completedCount: completed,
        isLoading: false,
        progressPercent: challenges.isEmpty ? 0 : completed / challenges.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleChallenge(int id) async {
    final updated = state.challenges.map((c) {
      if (c.id == id) return c.copyWith(isCompleted: !c.isCompleted);
      return c;
    }).toList();

    final completed = updated.where((c) => c.isCompleted).length;

    // Save to prefs
    final completedMap = <String, bool>{};
    for (final c in updated) {
      if (c.isCompleted) completedMap[c.id.toString()] = true;
    }
    await _prefs.setString('ramadan_completed', jsonEncode(completedMap));

    state = state.copyWith(
      challenges: updated,
      completedCount: completed,
      progressPercent: updated.isEmpty ? 0 : completed / updated.length,
    );
  }
}

final ramadanHabitsProvider =
    StateNotifierProvider<RamadanHabitsNotifier, RamadanHabitsState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return RamadanHabitsNotifier(prefs);
    });
