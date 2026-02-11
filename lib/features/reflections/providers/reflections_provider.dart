import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/providers/app_providers.dart';

class Reflection {
  final String id;
  final DateTime dateTime;
  final String prayerName;
  final int sentiment; // 1-5
  final String note;
  final List<String> tags;

  const Reflection({
    required this.id,
    required this.dateTime,
    required this.prayerName,
    required this.sentiment,
    required this.note,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateTime': dateTime.toIso8601String(),
    'prayerName': prayerName,
    'sentiment': sentiment,
    'note': note,
    'tags': tags,
  };

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
    id: json['id'],
    dateTime: DateTime.parse(json['dateTime']),
    prayerName: json['prayerName'],
    sentiment: json['sentiment'],
    note: json['note'] ?? '',
    tags: List<String>.from(json['tags'] ?? []),
  );
}

class ReflectionsState {
  final List<Reflection> reflections;
  final double averageSentiment;
  final int totalReflections;
  final Map<String, int> prayerCounts;

  const ReflectionsState({
    this.reflections = const [],
    this.averageSentiment = 0,
    this.totalReflections = 0,
    this.prayerCounts = const {},
  });

  ReflectionsState copyWith({
    List<Reflection>? reflections,
    double? averageSentiment,
    int? totalReflections,
    Map<String, int>? prayerCounts,
  }) {
    return ReflectionsState(
      reflections: reflections ?? this.reflections,
      averageSentiment: averageSentiment ?? this.averageSentiment,
      totalReflections: totalReflections ?? this.totalReflections,
      prayerCounts: prayerCounts ?? this.prayerCounts,
    );
  }

  List<Reflection> get last7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return reflections.where((r) => r.dateTime.isAfter(cutoff)).toList();
  }

  Map<int, int> get sentimentDistribution {
    final dist = <int, int>{};
    for (final r in reflections) {
      dist[r.sentiment] = (dist[r.sentiment] ?? 0) + 1;
    }
    return dist;
  }
}

class ReflectionsNotifier extends StateNotifier<ReflectionsState> {
  final SharedPreferences _prefs;

  ReflectionsNotifier(this._prefs) : super(const ReflectionsState()) {
    _loadData();
  }

  void _loadData() {
    final dataStr = _prefs.getString('salah_reflections');
    if (dataStr == null) return;

    final List<dynamic> jsonList = jsonDecode(dataStr);
    final reflections =
        jsonList
            .map((j) => Reflection.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    _updateState(reflections);
  }

  void _updateState(List<Reflection> reflections) {
    final total = reflections.length;
    final avg = total > 0
        ? reflections.map((r) => r.sentiment).reduce((a, b) => a + b) / total
        : 0.0;

    final prayerCounts = <String, int>{};
    for (final r in reflections) {
      prayerCounts[r.prayerName] = (prayerCounts[r.prayerName] ?? 0) + 1;
    }

    state = state.copyWith(
      reflections: reflections,
      averageSentiment: avg,
      totalReflections: total,
      prayerCounts: prayerCounts,
    );
  }

  Future<void> _saveData() async {
    final jsonList = state.reflections.map((r) => r.toJson()).toList();
    await _prefs.setString('salah_reflections', jsonEncode(jsonList));
  }

  Future<void> addReflection({
    required String prayerName,
    required int sentiment,
    required String note,
    List<String> tags = const [],
  }) async {
    final reflection = Reflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      prayerName: prayerName,
      sentiment: sentiment,
      note: note,
      tags: tags,
    );

    final updated = [reflection, ...state.reflections];
    _updateState(updated);
    await _saveData();
  }

  Future<void> deleteReflection(String id) async {
    final updated = state.reflections.where((r) => r.id != id).toList();
    _updateState(updated);
    await _saveData();
  }
}

final reflectionsProvider =
    StateNotifierProvider<ReflectionsNotifier, ReflectionsState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ReflectionsNotifier(prefs);
    });
