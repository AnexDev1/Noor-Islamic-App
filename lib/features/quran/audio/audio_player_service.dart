import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// Simple audio player without audio_service dependency
/// Use this as a fallback if audio_service continues to cause issues
class SimpleQuranAudioPlayer {
  static SimpleQuranAudioPlayer? _instance;
  static SimpleQuranAudioPlayer get instance {
    _instance ??= SimpleQuranAudioPlayer._internal();
    return _instance!;
  }
  SimpleQuranAudioPlayer._internal() {
    _initialize();
  }

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  // UI State Notifiers
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  ValueNotifier<String> currentSurahName = ValueNotifier('');
  ValueNotifier<String> currentReciter = ValueNotifier('');
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<bool> hasError = ValueNotifier(false);
  ValueNotifier<double> volume = ValueNotifier(1.0);
  ValueNotifier<double> speed = ValueNotifier(1.0);

  String? currentUrl;

  void _initialize() {
    _audioPlayer = AudioPlayer();
    _setupListeners();
    _isInitialized = true;
    debugPrint('Simple Audio Player initialized');
  }

  void _setupListeners() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isLoading.value = state.processingState == ProcessingState.loading ||
                      state.processingState == ProcessingState.buffering;

      hasError.value = false; // Reset error on state change

      // Handle completion
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        position.value = duration.value;
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
      }
    });

    // Listen to buffered position for progress indication
    _audioPlayer.bufferedPositionStream.listen((buffered) {
      // You can use this for showing buffered progress if needed
    });
  }

  /// Play audio from URL
  Future<void> play(String url, String surahName, {String? reciterName}) async {
    if (!_isInitialized) {
      throw Exception('Audio player not initialized');
    }

    try {
      debugPrint('Playing: $surahName from $url');

      isLoading.value = true;
      hasError.value = false;
      currentUrl = url;
      currentSurahName.value = surahName;
      currentReciter.value = reciterName ?? 'Abdul Baset Abdul Samad';

      // Set audio source
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));

      // Start playing
      await _audioPlayer.play();

      debugPrint('Audio started successfully');
    } catch (e) {
      debugPrint('Error playing audio: $e');
      isLoading.value = false;
      hasError.value = true;
      rethrow;
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      // If playback has completed, seek to the beginning before playing.
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
      hasError.value = true;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      hasError.value = true;
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _resetState();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Seek to specific position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
      hasError.value = true;
    }
  }

  /// Seek forward by 10 seconds
  Future<void> seekForward() async {
    final currentPos = position.value;
    final newPos = currentPos + const Duration(seconds: 10);
    final maxPos = duration.value;
    await seek(newPos > maxPos ? maxPos : newPos);
  }

  /// Seek backward by 10 seconds
  Future<void> seekBackward() async {
    final currentPos = position.value;
    final newPos = currentPos - const Duration(seconds: 10);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double vol) async {
    try {
      vol = vol.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(vol);
      volume.value = vol;
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double spd) async {
    try {
      spd = spd.clamp(0.5, 2.0);
      await _audioPlayer.setSpeed(spd);
      speed.value = spd;
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  /// Reset all state values
  void _resetState() {
    currentUrl = null;
    currentSurahName.value = '';
    currentReciter.value = '';
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isPlaying.value = false;
    isLoading.value = false;
    hasError.value = false;
  }

  /// Get current playback position as percentage (0.0 to 1.0)
  double get progressPercentage {
    if (duration.value.inMilliseconds == 0) return 0.0;
    return position.value.inMilliseconds / duration.value.inMilliseconds;
  }

  /// Check if audio is currently loaded
  bool get hasAudio => currentUrl != null && !hasError.value;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      debugPrint('Audio player disposed');
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
  }
}