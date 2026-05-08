import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ustaz.dart';
import '../domain/video_item.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

final ustazListProvider = FutureProvider<List<Ustaz>>((ref) async {
  final _yt = yt.YoutubeExplode();
  try {
    final scholars = [
      {'id': '1', 'name': 'Ustaz Bedru Hussein', 'channelId': 'UCluqbaJevNbnV256ooch8WQ'},
      {'id': '2', 'name': 'Ustaz Yassin Nuru', 'channelId': 'UCfDzAhe49MJr4K1GSmfapOA'},
      {'id': '3', 'name': 'Ustaz Abubeker Ahmed', 'channelId': 'UCbP882lEeCydm_kOycQ4qgw'},
      {'id': '4', 'name': 'Dawa Amharic', 'channelId': 'UCjZdMSM8Ke5S4bNQ2QYJFXA'},
      {'id': '5', 'name': 'Amharic Dawa', 'channelId': 'UCJSQbzDy9NShRMHiVWU4-Zg'},
      {'id': '6', 'name': 'Hamudi Tube', 'channelId': 'UCDxTW9uTYfMphaaBYNDZEmg'},
      {'id': '7', 'name': 'Nun Media', 'channelId': 'UCVp86h1vqpBEGYIgw6EJ6dA'},
      {'id': '8', 'name': 'Fillaah Tube', 'channelId': 'UC3wGyPkKdXJ6r5qUdhTgteA'},
      {'id': '9', 'name': 'Darul Towhid', 'channelId': 'UCebUjzTGpEN2Qz-fztXTfiw'},
      {'id': '10', 'name': 'Ustaz Khalid Kibrom', 'channelId': 'UCUvIsHZLh9maRJzCT6H5wyg'},
    ];

    final List<Ustaz> results = [];
    for (var s in scholars) {
      try {
        final channel = await _yt.channels.get(yt.ChannelId(s['channelId']!));
        results.add(Ustaz(
          id: s['id']!,
          name: s['name']!,
          imageUrl: channel.logoUrl,
          channelId: s['channelId'],
        ));
      } catch (e) {
        // Fallback for failed channel fetch
        results.add(Ustaz(
          id: s['id']!,
          name: s['name']!,
          imageUrl: 'https://img.youtube.com/vi/AoKok03H7jI/mqdefault.jpg', // generic placeholder
          channelId: s['channelId'],
        ));
      }
    }
    return results;
  } finally {
    _yt.close();
  }
});

class UstazVideosNotifier extends StateNotifier<AsyncValue<List<VideoItem>>> {
  final Ustaz ustaz;
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  StreamIterator<yt.Video>? _iterator;
  final List<VideoItem> _videos = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

  UstazVideosNotifier(this.ustaz) : super(const AsyncValue.loading()) {
    _init();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> _init() async {
    try {
      Stream<yt.Video>? stream;
      if (ustaz.channelId != null) {
        // Channel Uploads playlist is 'UU' + channelId.substring(2)
        final uploadsId = 'UU${ustaz.channelId!.substring(2)}';
        stream = _yt.playlists.getVideos(yt.PlaylistId(uploadsId));
      } else if (ustaz.playlistId != null) {
        stream = _yt.playlists.getVideos(yt.PlaylistId(ustaz.playlistId!));
      }

      if (stream != null) {
        _iterator = StreamIterator(stream);
        await fetchNextBatch();
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchNextBatch() async {
    if (!_hasMore || _isLoadingMore || _iterator == null) return;
    
    _isLoadingMore = true;
    try {
      int count = 0;
      while (count < 20 && await _iterator!.moveNext()) {
        _videos.add(VideoItem.fromYt(_iterator!.current));
        count++;
      }
      
      if (count == 0) {
        _hasMore = false;
      }
      
      state = AsyncValue.data(List.from(_videos));
    } catch (e, st) {
      print('Error in fetchNextBatch: $e\n$st');
      if (_videos.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }
}

class PlaylistVideosNotifier extends StateNotifier<AsyncValue<List<VideoItem>>> {
  final String playlistId;
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  StreamIterator<yt.Video>? _iterator;
  final List<VideoItem> _videos = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

  PlaylistVideosNotifier(this.playlistId) : super(const AsyncValue.loading()) {
    _init();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> _init() async {
    try {
      final stream = _yt.playlists.getVideos(yt.PlaylistId(playlistId));
      _iterator = StreamIterator(stream);
      await fetchNextBatch();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchNextBatch() async {
    if (!_hasMore || _isLoadingMore || _iterator == null) return;
    
    _isLoadingMore = true;
    try {
      int count = 0;
      while (count < 20 && await _iterator!.moveNext()) {
        _videos.add(VideoItem.fromYt(_iterator!.current));
        count++;
      }
      
      if (count == 0) {
        _hasMore = false;
      }
      
      state = AsyncValue.data(List.from(_videos));
    } catch (e, st) {
      if (_videos.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }
}

final paginatedVideosProvider = StateNotifierProvider.family<UstazVideosNotifier, AsyncValue<List<VideoItem>>, Ustaz>((ref, ustaz) {
  return UstazVideosNotifier(ustaz);
});

final playlistVideosProvider = StateNotifierProvider.family<PlaylistVideosNotifier, AsyncValue<List<VideoItem>>, String>((ref, playlistId) {
  return PlaylistVideosNotifier(playlistId);
});


