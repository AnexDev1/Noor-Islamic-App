import 'package:audio_service/audio_service.dart';
import 'quran_audio_handler.dart';
import 'package:flutter/foundation.dart';

class QuranAudioPlayerService {
  static final QuranAudioPlayerService _instance = QuranAudioPlayerService._internal();
  factory QuranAudioPlayerService() => _instance;
  QuranAudioPlayerService._internal();

  QuranAudioHandler? _audioHandler;

  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  ValueNotifier<String> currentSurahName = ValueNotifier('');
  ValueNotifier<String> currentReciter = ValueNotifier('');
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<bool> hasError = ValueNotifier(false);

  String? currentUrl;

  Future<void> init() async {
    if (_audioHandler == null) {
      try {
        _audioHandler = await AudioService.init(
          builder: () => QuranAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.noor.quran.audio',
            androidNotificationChannelName: 'Noor - Quran Audio',
            androidNotificationOngoing: true,
            androidShowNotificationBadge: true,
            androidNotificationClickStartsActivity: true,
            androidNotificationIcon: 'drawable/ic_notification',
            fastForwardInterval: Duration(seconds: 10),
            rewindInterval: Duration(seconds: 10),
          ),
        );

        // Listen to audio handler state changes
        _audioHandler!.playbackState.listen((state) {
          isPlaying.value = state.playing;
          position.value = state.updatePosition;
          isLoading.value = state.processingState == AudioProcessingState.loading ||
                           state.processingState == AudioProcessingState.buffering;
          hasError.value = state.processingState == AudioProcessingState.error;
        });

        _audioHandler!.mediaItem.listen((item) {
          if (item != null) {
            duration.value = item.duration ?? Duration.zero;
            currentSurahName.value = item.title ?? '';
            currentReciter.value = item.artist ?? '';
          } else {
            // Clear all values when mediaItem is null
            duration.value = Duration.zero;
            currentSurahName.value = '';
            currentReciter.value = '';
            position.value = Duration.zero;
            isPlaying.value = false;
            isLoading.value = false;
          }
        });
      } catch (e) {
        debugPrint('Error initializing audio service: $e');
        hasError.value = true;
      }
    }
  }

  Future<void> play(String url, String surahName, {String? reciterName}) async {
    try {
      await init(); // Ensure service is initialized

      isLoading.value = true;
      hasError.value = false;
      currentUrl = url;

      final handler = _audioHandler as QuranAudioHandler?;
      if (handler != null) {
        await handler.playMedia(
          url,
          surahName,
          reciterName ?? 'Abdul Baset Abdul Samad'
        );
      } else {
        throw Exception('Audio handler not initialized');
      }
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioHandler?.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      hasError.value = true;
    }
  }

  Future<void> resume() async {
    try {
      await _audioHandler?.play();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
      hasError.value = true;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioHandler?.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
      hasError.value = true;
    }
  }

  Future<void> seekForward() async {
    final currentPos = position.value;
    final newPos = currentPos + const Duration(seconds: 10);
    final maxPos = duration.value;
    await seek(newPos > maxPos ? maxPos : newPos);
  }

  Future<void> seekBackward() async {
    final currentPos = position.value;
    final newPos = currentPos - const Duration(seconds: 10);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> stop() async {
    try {
      await _audioHandler?.stop();
      currentUrl = null;
      // Note: ValueNotifiers will be updated via mediaItem listener
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  bool get isInitialized => _audioHandler != null;

  void dispose() {
    stop();
    _audioHandler?.stop();
  }
}
