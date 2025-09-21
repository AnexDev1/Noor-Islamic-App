// import 'package:just_audio/just_audio.dart';
// import 'package:flutter/foundation.dart';
//
// class QuranAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//
//   QuranAudioHandler() {
//     _init();
//   }
//
//   void _init() {
//     // Listen to audio player state changes
//     _audioPlayer.playbackEventStream.listen((event) {
//       _broadcastState();
//     });
//
//     // Listen to position changes
//     _audioPlayer.positionStream.listen((position) {
//       playbackState.add(playbackState.value.copyWith(updatePosition: position));
//     });
//
//     // Listen to player state changes
//     _audioPlayer.playerStateStream.listen((state) {
//       _broadcastState();
//     });
//
//     // Listen to sequence state changes for queue updates
//     _audioPlayer.sequenceStateStream.listen((sequenceState) {
//       if (sequenceState != null) {
//         final currentItem = sequenceState.currentSource;
//         if (currentItem != null && currentItem.tag != null) {
//           mediaItem.add(currentItem.tag as MediaItem);
//         }
//       }
//     });
//
//     // Initialize with idle state
//     playbackState.add(PlaybackState(
//       controls: [
//         MediaControl.play,
//       ],
//       processingState: AudioProcessingState.idle,
//       playing: false,
//     ));
//   }
//
//   void _broadcastState() {
//     playbackState.add(PlaybackState(
//       controls: _getControls(),
//       systemActions: const {
//         MediaAction.seek,
//         MediaAction.seekForward,
//         MediaAction.seekBackward,
//       },
//       androidCompactActionIndices: const [0, 1, 2],
//       processingState: _mapProcessingState(_audioPlayer.processingState),
//       playing: _audioPlayer.playing,
//       updatePosition: _audioPlayer.position,
//       bufferedPosition: _audioPlayer.bufferedPosition,
//       speed: _audioPlayer.speed,
//       queueIndex: _audioPlayer.currentIndex,
//     ));
//   }
//
//   List<MediaControl> _getControls() {
//     return [
//       MediaControl.rewind,
//       _audioPlayer.playing ? MediaControl.pause : MediaControl.play,
//       MediaControl.fastForward,
//       MediaControl.stop,
//     ];
//   }
//
//   AudioProcessingState _mapProcessingState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }
//
//   Future<void> playMedia(String url, String title, String artist) async {
//     try {
//       debugPrint('Playing media: $url');
//
//       // Create media item
//       final mediaItem = MediaItem(
//         id: url,
//         title: title,
//         artist: artist,
//         duration: null,
//         artUri: null,
//       );
//
//       // Set media item immediately
//       this.mediaItem.add(mediaItem);
//
//       // Create audio source with metadata
//       final audioSource = AudioSource.uri(
//         Uri.parse(url),
//         tag: mediaItem,
//       );
//
//       // Set the audio source
//       await _audioPlayer.setAudioSource(audioSource);
//
//       // Update duration once loaded
//       final duration = _audioPlayer.duration;
//       if (duration != null) {
//         this.mediaItem.add(mediaItem.copyWith(duration: duration));
//       }
//
//       // Start playing
//       await _audioPlayer.play();
//
//       debugPrint('Media playing started successfully');
//     } catch (e) {
//       debugPrint('Error in playMedia: $e');
//       playbackState.add(playbackState.value.copyWith(
//         processingState: AudioProcessingState.error,
//       ));
//       rethrow;
//     }
//   }
//
//   @override
//   Future<void> play() async {
//     try {
//       await _audioPlayer.play();
//       debugPrint('Play called');
//     } catch (e) {
//       debugPrint('Error in play: $e');
//       playbackState.add(playbackState.value.copyWith(
//         processingState: AudioProcessingState.error,
//       ));
//     }
//   }
//
//   @override
//   Future<void> pause() async {
//     try {
//       await _audioPlayer.pause();
//       debugPrint('Pause called');
//     } catch (e) {
//       debugPrint('Error in pause: $e');
//     }
//   }
//
//   @override
//   Future<void> seek(Duration position) async {
//     try {
//       await _audioPlayer.seek(position);
//       debugPrint('Seek to: $position');
//     } catch (e) {
//       debugPrint('Error in seek: $e');
//     }
//   }
//
//   @override
//   Future<void> stop() async {
//     try {
//       await _audioPlayer.stop();
//       mediaItem.add(null);
//       playbackState.add(PlaybackState(
//         controls: [MediaControl.play],
//         processingState: AudioProcessingState.idle,
//         playing: false,
//       ));
//       debugPrint('Stop called');
//     } catch (e) {
//       debugPrint('Error in stop: $e');
//     }
//   }
//
//   @override
//   Future<void> rewind() async {
//     final position = _audioPlayer.position;
//     final newPosition = position - const Duration(seconds: 10);
//     await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
//   }
//
//   @override
//   Future<void> fastForward() async {
//     final position = _audioPlayer.position;
//     final duration = _audioPlayer.duration;
//     if (duration != null) {
//       final newPosition = position + const Duration(seconds: 10);
//       await seek(newPosition > duration ? duration : newPosition);
//     }
//   }
//
//   @override
//   Future<void> onTaskRemoved() async {
//     await stop();
//     await super.onTaskRemoved();
//   }
//
//   @override
//   Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
//     switch (name) {
//       case 'dispose':
//         await _audioPlayer.dispose();
//         break;
//       default:
//         super.customAction(name, extras);
//     }
//   }
//
//   Future<void> dispose() async {
//     await _audioPlayer.dispose();
//   }
// }