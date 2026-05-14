import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class TajweedAudioService {
  static TajweedAudioService? _instance;
  static TajweedAudioService get instance {
    _instance ??= TajweedAudioService._internal();
    return _instance!;
  }

  TajweedAudioService._internal() {
    _initialize();
  }

  late AudioPlayer _audioPlayer;
  List<int> _ayahNumbers = [];

  // UI Notifiers
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  ValueNotifier<int> currentAyahNumber = ValueNotifier(-1);
  ValueNotifier<int> currentSurahNumber = ValueNotifier(-1);
  ValueNotifier<String> currentSurahName = ValueNotifier('');
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<double> speed = ValueNotifier(1.0);

  void _initialize() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isLoading.value =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _ayahNumbers.length) {
        currentAyahNumber.value = _ayahNumbers[index];
      }
    });
  }

  Future<void> loadAyahRange({
    required int surahNo,
    required String surahName,
    required int startAyah,
    required int endAyah,
    required String folderName,
    required int repeatCount, // How many times EACH ayah repeats
    bool loopEntireRange = false,
  }) async {
    isLoading.value = true;
    currentSurahNumber.value = surahNo;
    currentSurahName.value = surahName;
    _ayahNumbers.clear();
    try {
      final List<AudioSource> audioSources = [];

      final surahStr = surahNo.toString().padLeft(3, '0');

      for (int i = startAyah; i <= endAyah; i++) {
        final ayahStr = i.toString().padLeft(3, '0');
        final url =
            'https://everyayah.com/data/$folderName/$surahStr$ayahStr.mp3';

        for (int r = 0; r < repeatCount; r++) {
          audioSources.add(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: '${surahStr}${ayahStr}_$r', // Unique ID needed
                album: surahName,
                title: 'Ayah $i',
                artist: folderName,
              ),
            ),
          );
          _ayahNumbers.add(i);
        }
      }

      final playlist = ConcatenatingAudioSource(children: audioSources);

      await _audioPlayer.setLoopMode(
        loopEntireRange ? LoopMode.all : LoopMode.off,
      );
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      if (_ayahNumbers.isNotEmpty) {
        currentAyahNumber.value = _ayahNumbers[0];
      }

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error loading playlist: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
    isPlaying.value = true;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    isPlaying.value = false;
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    currentAyahNumber.value = -1;
    currentSurahNumber.value = -1;
    currentSurahName.value = '';
    isPlaying.value = false;
    isLoading.value = false;
  }

  Future<void> seekToNext() async => _audioPlayer.seekToNext();
  Future<void> seekToPrevious() async => _audioPlayer.seekToPrevious();

  Future<void> setSpeed(double s) async {
    await _audioPlayer.setSpeed(s);
    speed.value = s;
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
