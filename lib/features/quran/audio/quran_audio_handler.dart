import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

  QuranAudioHandler() {
    // Listen to position changes
    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      _updatePlaybackState();
    });

    // Listen to duration changes
    _player.onDurationChanged.listen((duration) {
      _currentDuration = duration;
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      _updatePlaybackState();
    });

    // Listen to player state changes
    _player.onPlayerStateChanged.listen((state) {
      _updatePlaybackState();
    });

    // Listen to player completion
    _player.onPlayerComplete.listen((_) {
      _updatePlaybackState();
    });
  }

  void _updatePlaybackState() {
    final state = _player.state;
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
      bufferedPosition: _currentPosition,
      speed: 1.0,
      queueIndex: 0,
    ));
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
      case PlayerState.disposed:
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
        duration: _currentDuration > Duration.zero ? _currentDuration : null,
        extras: {
          'url': url,
        },
      ));

      // Update state to loading
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
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

      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
    } catch (e) {
      debugPrint('Error in stop: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _currentPosition = position;
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
    final duration = _currentDuration;
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

  void dispose() async {
    await _player.dispose();
  }
}
