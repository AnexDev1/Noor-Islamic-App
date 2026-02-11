import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../domain/surah_info.dart';

class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Audio speed
  double _speed = 1.0;

  // Playlist state
  List<SurahInfo> _playlist = [];
  int _currentIndex = 0;
  String _currentReciterId = 'ar.alafasy';
  String _currentReciterName = 'Mishary Rashid Al-Afasy';

  QuranAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Listen to playback events
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _currentIndex,
        ),
      );
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      final oldState = playbackState.value;
      playbackState.add(oldState.copyWith(updatePosition: position));
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      final currentMedia = mediaItem.value;
      if (currentMedia != null) {
        mediaItem.add(currentMedia.copyWith(duration: duration));
      }
    });

    // Handle completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  void setContext(
    List<SurahInfo> surahs,
    String reciterId,
    String reciterName,
  ) {
    _playlist = surahs;
    _currentReciterId = reciterId;
    _currentReciterName = reciterName;
  }

  Future<void> playSurahAtIndex(int index) async {
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final surah = _playlist[index];
    final surahNumber = index + 1;

    final url = _getStreamUrl(surahNumber, _currentReciterId);
    final imageUrl = _getReciterImage(_currentReciterId);

    await playUrl(
      url,
      title: surah.surahName,
      artist: _currentReciterName,
      artUri: imageUrl,
    );
  }

  String _getReciterImage(String reciterId) {
    if (reciterId == '1' || reciterId == 'ar.alafasy') {
      return 'https://archive.org/services/img/AbdallahKamelSura113AlFalaq_201906/full/pct:500/0/default.jpg';
    } else if (reciterId == '2' || reciterId.contains('shatri')) {
      return 'https://darulquran.co.uk/wp-content/uploads/2021/03/Abu-Bakr-al-Shatri.jpg';
    } else if (reciterId == '3' || reciterId.contains('qatami')) {
      return 'https://i1.sndcdn.com/artworks-IUNBxRxsvNOlQ55w-xPQ9Yw-t500x500.jpg';
    } else if (reciterId == '4' || reciterId.contains('dosari')) {
      return 'https://yt3.googleusercontent.com/xRV_h3jtjMySlb5BSnMkR2kWq4lfeElaNfWCe6RXkjuxX_MDb91bVOfgWQs8ph1J0VIxNZu3OVQ=s900-c-k-c0x00ffffff-no-rj';
    } else if (reciterId == '5' || reciterId.contains('rifai')) {
      return 'https://storage.googleapis.com/way2quran_storage/imgs/hani-al-rifai.jpg';
    }
    // Default fallback
    return 'https://cdn-icons-png.flaticon.com/512/3220/3220461.png';
  }

  String _getStreamUrl(int surahNumber, String reciterId) {
    String paddedSurah = surahNumber.toString().padLeft(3, '0');

    // Mappings based on quranicaudio.com path names
    if (reciterId == '1' || reciterId == 'ar.alafasy') {
      return 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$paddedSurah.mp3';
    } else if (reciterId == '2' || reciterId.contains('shatri')) {
      return 'https://download.quranicaudio.com/quran/abu_bakr_ash-shaatree/$paddedSurah.mp3';
    } else if (reciterId == '3' || reciterId.contains('qatami')) {
      return 'https://download.quranicaudio.com/quran/nasser_alqatami/$paddedSurah.mp3';
    } else if (reciterId == '4' || reciterId.contains('dosari')) {
      return 'https://download.quranicaudio.com/quran/yasser_ad-dussary/$paddedSurah.mp3';
    } else if (reciterId == '5' || reciterId.contains('rifai')) {
      return 'https://download.quranicaudio.com/quran/hani_ar_rifai/$paddedSurah.mp3';
    }
    // Legacy/Extra fallbacks
    else if (reciterId.contains('sudais')) {
      return 'https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays/$paddedSurah.mp3';
    } else if (reciterId.contains('shuraym')) {
      return 'https://download.quranicaudio.com/quran/sa3ood_al-shuraym/$paddedSurah.mp3';
    } else if (reciterId.contains('maher')) {
      return 'https://download.quranicaudio.com/quran/maher_almu3aiqly/year1440/$paddedSurah.mp3';
    } else {
      // Default to Al-Afasy if ID is unknown
      return 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$paddedSurah.mp3';
    }
  }

  Future<void> playUrl(
    String url, {
    required String title,
    required String artist,
    String? artUri,
  }) async {
    try {
      final item = MediaItem(
        id: url,
        album: "Quran",
        title: title,
        artist: artist,
        artUri: artUri != null ? Uri.tryParse(artUri) : null,
      );

      mediaItem.add(item);

      // Set audio source
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.setSpeed(_speed);
      await _player.play();
    } catch (e) {
      if (kDebugMode) {
        print("Error playing audio: $e");
      }

      String msg = "Unable to play audio.";
      if (e.toString().contains('404') ||
          e.toString().contains('PlayerException')) {
        msg =
            "No audio found for this reciter/surah. Please try another reciter.";
      }

      throw Exception(msg);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      await playSurahAtIndex(_currentIndex + 1);
    } else {
      await stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isNotEmpty && _currentIndex > 0) {
      await playSurahAtIndex(_currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _player.setSpeed(speed);
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  @override
  Future<void> rewind() async {
    final pos = _player.position;
    final newPos = pos - const Duration(seconds: 10);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  @override
  Future<void> fastForward() async {
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final newPos = pos + const Duration(seconds: 10);
    await seek(newPos > dur ? dur : newPos);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
