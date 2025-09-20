import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();
  Duration _currentPosition = Duration.zero;

  QuranAudioHandler() {
    // Listen to position changes
    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      playbackState.add(playbackState.value.copyWith(
        updatePosition: pos,
      ));
    });

    // Listen to duration changes
    _player.onDurationChanged.listen((duration) {
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    });

    // Listen to player state changes
    _player.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;

      playbackState.add(PlaybackState(
        controls: [
          MediaControl.rewind,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2, 3],
        playing: isPlaying,
        processingState: _mapPlayerState(state),
        updatePosition: _currentPosition,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ));
    });

    // Listen to player completion
    _player.onPlayerComplete.listen((_) {
      stop();
    });
  }

  AudioProcessingState _mapPlayerState(PlayerState state) {
    switch (state) {
      case PlayerState.stopped:
        return AudioProcessingState.idle;
      case PlayerState.playing:
        return AudioProcessingState.ready;
      case PlayerState.paused:
        return AudioProcessingState.ready;
      case PlayerState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  Future<void> playMedia(String url, String surahName, String reciterName) async {
    try {
      // Stop current playback first
      if (_player.state == PlayerState.playing || _player.state == PlayerState.paused) {
        await _player.stop();
      }

      // Set media item for notification
      mediaItem.add(MediaItem(
        id: url,
        title: surahName,
        artist: reciterName,
        album: 'Holy Quran',
        artUri: Uri.parse('android.resource://com.noor.app/drawable/quran_cover'),
        duration: null, // Will be updated when duration is available
        extras: {
          'url': url,
        },
      ));

      // Start playback
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error in playMedia: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
    }
  }

  @override
  Future<void> play() async {
    try {
      final currentMediaItem = mediaItem.value;
      if (currentMediaItem != null) {
        if (_player.state == PlayerState.paused) {
          await _player.resume();
        } else {
          final url = currentMediaItem.extras?['url'] as String?;
          if (url != null) {
            await _player.play(UrlSource(url));
          }
        }
      }
    } catch (e) {
      debugPrint('Error in play: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error in pause: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();

      // Clear media item
      mediaItem.add(null);

      // Reset playback state
      playbackState.add(PlaybackState(
        controls: [],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ));
    } catch (e) {
      debugPrint('Error in stop: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error in seek: $e');
    }
  }

  @override
  Future<void> rewind() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  @override
  Future<void> fastForward() async {
    final duration = mediaItem.value?.duration ?? Duration.zero;
    final newPosition = _currentPosition + const Duration(seconds: 10);
    await seek(newPosition > duration ? duration : newPosition);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Stop playback when app is removed from recent tasks
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Stop playback when notification is dismissed
    await stop();
  }
}
