import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../domain/video_item.dart';

/// Reliable fallback for YouTube's frequently-changing internal endpoints.
///
/// YouTube's official Atom feed exposes the latest 15 public uploads without
/// requiring an API key. Results are cached so a previously loaded channel
/// remains available when the device is offline.
class YoutubeFeedService {
  YoutubeFeedService({http.Client? client}) : _client = client ?? http.Client();

  static const _requestTimeout = Duration(seconds: 12);
  static const _cachePrefix = 'youtube_channel_feed_v1_';
  final http.Client _client;

  Future<List<VideoItem>> fetchLatest(String channelId) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client
            .get(
              Uri.https('www.youtube.com', '/feeds/videos.xml', {
                'channel_id': channelId,
              }),
              headers: const {'Accept': 'application/atom+xml'},
            )
            .timeout(_requestTimeout);
        if (response.statusCode != 200) {
          throw http.ClientException(
            'YouTube feed returned HTTP ${response.statusCode}',
          );
        }

        final videos = _parseFeed(response.body);
        if (videos.isEmpty) {
          throw const FormatException('YouTube feed contained no videos');
        }
        await _saveCache(channelId, videos);
        return videos;
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 400 << attempt));
        }
      }
    }

    final cached = await loadCached(channelId);
    if (cached.isNotEmpty) return cached;
    throw StateError('Unable to load YouTube videos: $lastError');
  }

  Future<List<VideoItem>> loadCached(String channelId) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('$_cachePrefix$channelId');
    if (value == null) return const [];
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .map((item) => VideoItem.fromMap(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      await preferences.remove('$_cachePrefix$channelId');
      return const [];
    }
  }

  List<VideoItem> _parseFeed(String source) {
    final document = XmlDocument.parse(source);
    return document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'entry')
        .map((entry) {
          String text(String localName) => entry.descendants
              .whereType<XmlElement>()
              .firstWhere(
                (element) => element.name.local == localName,
                orElse: () => XmlElement(XmlName(localName)),
              )
              .innerText
              .trim();

          final id = text('videoId');
          final thumbnail = entry.descendants
              .whereType<XmlElement>()
              .where((element) => element.name.local == 'thumbnail')
              .map((element) => element.getAttribute('url'))
              .whereType<String>()
              .firstOrNull;
          final views = entry.descendants
              .whereType<XmlElement>()
              .where((element) => element.name.local == 'statistics')
              .map(
                (element) => int.tryParse(element.getAttribute('views') ?? ''),
              )
              .whereType<int>()
              .firstOrNull;

          return VideoItem(
            id: id,
            title: text('title'),
            author: text('name'),
            thumbnailUrl:
                thumbnail ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
            uploadDateIso: text('published'),
            viewCount: views,
          );
        })
        .where((video) => video.id.isNotEmpty && video.title.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _saveCache(String channelId, List<VideoItem> videos) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_cachePrefix$channelId',
      jsonEncode(videos.map((video) => video.toMap()).toList()),
    );
  }

  void close() => _client.close();
}
