import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/app_providers.dart';
import '../models/reciter.dart';

class TajweedState {
  final String selectedReciterId;
  final int repeatCount;
  final bool loopRange;
  final double playbackSpeed;

  const TajweedState({
    this.selectedReciterId = 'alafasy',
    this.repeatCount = 1,
    this.loopRange = false,
    this.playbackSpeed = 1.0,
  });

  TajweedState copyWith({
    String? selectedReciterId,
    int? repeatCount,
    bool? loopRange,
    double? playbackSpeed,
  }) {
    return TajweedState(
      selectedReciterId: selectedReciterId ?? this.selectedReciterId,
      repeatCount: repeatCount ?? this.repeatCount,
      loopRange: loopRange ?? this.loopRange,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class TajweedNotifier extends StateNotifier<TajweedState> {
  final SharedPreferences _prefs;

  TajweedNotifier(this._prefs) : super(const TajweedState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final reciter = _prefs.getString('tajweed_reciter') ?? 'alafasy';
    final repeat = _prefs.getInt('tajweed_repeat') ?? 1;
    final loop = _prefs.getBool('tajweed_loop') ?? false;
    final speed = _prefs.getDouble('tajweed_speed') ?? 1.0;

    state = state.copyWith(
      selectedReciterId: reciter,
      repeatCount: repeat,
      loopRange: loop,
      playbackSpeed: speed,
    );
  }

  Future<void> updateReciter(String reciterId) async {
    await _prefs.setString('tajweed_reciter', reciterId);
    state = state.copyWith(selectedReciterId: reciterId);
  }

  Future<void> updateRepeatCount(int count) async {
    await _prefs.setInt('tajweed_repeat', count);
    state = state.copyWith(repeatCount: count);
  }

  Future<void> updateLoopRange(bool loop) async {
    await _prefs.setBool('tajweed_loop', loop);
    state = state.copyWith(loopRange: loop);
  }

  Future<void> updatePlaybackSpeed(double speed) async {
    await _prefs.setDouble('tajweed_speed', speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  TajweedReciter get currentReciter {
    return popularTajweedReciters.firstWhere(
      (r) => r.id == state.selectedReciterId,
      orElse: () => popularTajweedReciters.first,
    );
  }
}

final tajweedProvider = StateNotifierProvider<TajweedNotifier, TajweedState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TajweedNotifier(prefs);
});
