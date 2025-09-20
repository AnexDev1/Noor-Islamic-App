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
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  String? currentUrl;

  Future<void> init() async {
    if (_audioHandler == null) {
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
      });

      _audioHandler!.mediaItem.listen((item) {
        duration.value = item?.duration ?? Duration.zero;
        currentSurahName.value = item?.title ?? '';
      });
    }
  }

  Future<void> play(String url, String surahName, {String? reciterName}) async {
    try {
      // Stop current audio first to prevent multiple streams
      await stop();

      isLoading.value = true;
      currentUrl = url;
      currentSurahName.value = surahName;

      // Call playMedia with the correct 3 parameters
      final handler = _audioHandler as QuranAudioHandler?;
      if (handler != null) {
        await handler.playMedia(
          url,
          surahName,
          reciterName ?? 'Abdul Baset Abdul Samad'
        );
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    await _audioHandler?.pause();
  }

  Future<void> resume() async {
    await _audioHandler?.play();
  }

  Future<void> seek(Duration position) async {
    await _audioHandler?.seek(position);
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
    await _audioHandler?.stop();
    currentUrl = null;
    currentSurahName.value = '';
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isPlaying.value = false;
    isLoading.value = false;
  }

  void dispose() {
    stop();
    _audioHandler?.stop();
  }
}
