import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart';

class AyahCard {
  final String surah;
  final int ayahNumber;
  final String ref;
  final String arabic;
  final String translation;
  final String cardStyle; // nightSky, minimal, geometric, watercolor

  const AyahCard({
    required this.surah,
    required this.ayahNumber,
    required this.ref,
    required this.arabic,
    required this.translation,
    this.cardStyle = 'nightSky',
  });

  AyahCard copyWith({String? cardStyle}) => AyahCard(
    surah: surah,
    ayahNumber: ayahNumber,
    ref: ref,
    arabic: arabic,
    translation: translation,
    cardStyle: cardStyle ?? this.cardStyle,
  );
}

class AyahOfDayState {
  final AyahCard? todayAyah;
  final List<AyahCard> allAyahs;
  final bool isLoading;
  final String selectedStyle;

  const AyahOfDayState({
    this.todayAyah,
    this.allAyahs = const [],
    this.isLoading = true,
    this.selectedStyle = 'nightSky',
  });

  AyahOfDayState copyWith({
    AyahCard? todayAyah,
    List<AyahCard>? allAyahs,
    bool? isLoading,
    String? selectedStyle,
  }) {
    return AyahOfDayState(
      todayAyah: todayAyah ?? this.todayAyah,
      allAyahs: allAyahs ?? this.allAyahs,
      isLoading: isLoading ?? this.isLoading,
      selectedStyle: selectedStyle ?? this.selectedStyle,
    );
  }
}

class AyahOfDayNotifier extends StateNotifier<AyahOfDayState> {
  final SharedPreferences _prefs;

  AyahOfDayNotifier(this._prefs) : super(const AyahOfDayState()) {
    _loadAyahs();
  }

  Future<void> _loadAyahs() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/ayah_collection.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final ayahs = jsonList
          .map(
            (j) => AyahCard(
              surah: j['surah'],
              ayahNumber: j['ayah'],
              ref: j['ref'],
              arabic: j['ar'], // Fixed key from 'arabic' to 'ar'
              translation: j['en'], // Fixed key from 'translation' to 'en'
            ),
          )
          .toList();

      // Pick today's ayah deterministically based on date
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final index = dayOfYear % ayahs.length;
      final savedStyle = _prefs.getString('ayah_card_style') ?? 'nightSky';

      state = state.copyWith(
        allAyahs: ayahs,
        todayAyah: ayahs[index].copyWith(cardStyle: savedStyle),
        isLoading: false,
        selectedStyle: savedStyle,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void changeStyle(String style) {
    _prefs.setString('ayah_card_style', style);
    state = state.copyWith(
      selectedStyle: style,
      todayAyah: state.todayAyah?.copyWith(cardStyle: style),
    );
  }

  void randomAyah() {
    if (state.allAyahs.isEmpty) return;
    final index = Random().nextInt(state.allAyahs.length);
    state = state.copyWith(
      todayAyah: state.allAyahs[index].copyWith(cardStyle: state.selectedStyle),
    );
  }
}

final ayahOfDayProvider =
    StateNotifierProvider<AyahOfDayNotifier, AyahOfDayState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AyahOfDayNotifier(prefs);
    });
