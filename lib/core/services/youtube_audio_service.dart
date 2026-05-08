import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';

/// Service for extracting audio streams from YouTube videos
class YouTubeAudioService {
  static YouTubeAudioService? _instance;
  static YouTubeAudioService get instance =>
      _instance ??= YouTubeAudioService._();

  YouTubeAudioService._();

  final YoutubeExplode _youtube = YoutubeExplode();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (status) => true, // Don't throw on 403/502
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'en-US,en;q=0.9',
        'App-Name': 'Noor', // Some Piped instances require this
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-site',
        'Connection': 'keep-alive',
      },
    ),
  );

  // Piped & Invidious instances for fallback (fresh list)
  List<String> _fallbackInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.smnz.de',
    'https://piped-api.lunar.icu',
    'https://api.piped.privacydev.net',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.us.projectsegfau.lt',
    'https://api.piped.yt',
    'https://invidious.fdn.fr/api/v1',
    'https://invidious.perennialte.ch/api/v1',
    'https://vid.puffyan.us/api/v1',
    'https://invidious.flokinet.to/api/v1',
    'https://yt.artemislena.eu/api/v1',
    'https://iv.ggtyler.dev/api/v1',
    'https://invidious.jing.rocks/api/v1',
  ];

  // Cobalt API for high-reliability fallback
  final List<String> _cobaltInstances = [
    'https://co.wuk.sh/api/json',
    'https://api.cobalt.tools/api/json',
    'https://cobalt.kavin.rocks/api/json',
    'https://cobalt.drgns.space/api/json',
    'https://cobalt.kwiatechu.com/api/json',
    'https://cobalt.canine.ly/api/json',
    'https://cobalt.dov.me/api/json',
    'https://co.pussthecat.org/api/json',
  ];

  bool _instancesInitialized = false;

  Future<void> _initFallbackInstances() async {
    if (_instancesInitialized) return;
    try {
      // Try to get fresh piped instances
      final response = await _dio.get('https://piped-instances.kavin.rocks/');
      if (response.statusCode == 200 && response.data is List) {
        final List newInstances = response.data;
        final activeOnes = newInstances
            .where((i) => i['api'] == true && i['up'] == true)
            .map((i) => i['api_url'] as String)
            .toList();
        if (activeOnes.isNotEmpty) {
          _fallbackInstances.addAll(activeOnes);
          _fallbackInstances = _fallbackInstances.toSet().toList(); // Unique
        }
      }
    } catch (e) {
      debugPrint('YouTubeAudioService: Error fetching fresh instances: $e');
    }
    _instancesInitialized = true;
  }

  // Cache extracted URLs to avoid repeated API calls (they expire, so cache for limited time)
  final Map<String, _CachedUrl> _urlCache = {};
  static const _cacheValidityDuration = Duration(minutes: 30);

  /// Check if a URL is a YouTube URL or video ID
  static bool isYouTubeUrl(String url) {
    if (url.isEmpty) return false;

    // Check for common YouTube URL patterns
    final patterns = [
      RegExp(r'^https?://(?:www\.)?youtube\.com/watch\?v=[\w-]+'),
      RegExp(r'^https?://youtu\.be/[\w-]+'),
      RegExp(r'^https?://(?:www\.)?youtube\.com/embed/[\w-]+'),
      RegExp(r'^https?://(?:www\.)?youtube\.com/v/[\w-]+'),
      RegExp(r'^https?://(?:m\.)?youtube\.com/watch\?v=[\w-]+'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(url)) return true;
    }

    // Check if it's just a video ID (11 characters, alphanumeric with - and _)
    if (RegExp(r'^[\w-]{11}$').hasMatch(url)) {
      return true;
    }

    return false;
  }

  /// Extract the video ID from a YouTube URL
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    // If it's already just a video ID
    if (RegExp(r'^[\w-]{11}$').hasMatch(url)) {
      return url;
    }

    // Try to extract from various URL formats
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([\w-]{11})'),
      RegExp(r'youtu\.be/([\w-]{11})'),
      RegExp(r'youtube\.com/embed/([\w-]{11})'),
      RegExp(r'youtube\.com/v/([\w-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Get the audio stream URL for a YouTube video
  /// Returns null if extraction fails
  Future<String?> getAudioStreamUrl(String videoIdOrUrl) async {
    try {
      final videoId = extractVideoId(videoIdOrUrl);
      if (videoId == null) return null;

      await _initFallbackInstances();

      // Check cache first
      final cached = _urlCache[videoId];
      if (cached != null && !cached.isExpired) {
        debugPrint('YouTubeAudioService: Using cached URL for $videoId');
        return cached.url;
      }

      debugPrint(
        'YouTubeAudioService: Extracting audio stream for video: $videoId',
      );

      // 1. Try Cobalt (High-res audio extraction)
      final cobaltUrl = await _getCobaltStreamUrl(videoId);
      if (cobaltUrl != null) {
        _urlCache[videoId] = _CachedUrl(cobaltUrl, DateTime.now());
        return cobaltUrl;
      }

      // 2. Try YoutubeExplode (Primary)
      try {
        final manifest = await _youtube.videos.streamsClient.getManifest(
          videoId,
        );
        final muxed = manifest.muxed.toList();
        if (muxed.isNotEmpty) {
          muxed.sort((a, b) => b.bitrate.compareTo(a.bitrate));
          final url = muxed.first.url.toString();
          _urlCache[videoId] = _CachedUrl(url, DateTime.now());
          return url;
        }
      } catch (e) {
        debugPrint('YouTubeAudioService: YoutubeExplode failed: $e');
      }

      // 3. Try Muxiv (Muxed) API
      final muxivUrl = await _getMuxivStreamUrl(videoId);
      if (muxivUrl != null) {
        _urlCache[videoId] = _CachedUrl(muxivUrl, DateTime.now());
        return muxivUrl;
      }

      // 4. Try Fallback Instances (Piped/Invidious)
      final fallbackUrl = await _getFallbackStreamUrl(videoId);
      if (fallbackUrl != null) {
        _urlCache[videoId] = _CachedUrl(fallbackUrl, DateTime.now());
        return fallbackUrl;
      }

      debugPrint('YouTubeAudioService: All extraction methods failed');
      return null;
    } catch (e) {
      debugPrint('YouTubeAudioService: General extraction error: $e');
      return null;
    }
  }

  /// Extraction using Cobalt API with rotation
  Future<String?> _getCobaltStreamUrl(String videoId) async {
    final shuffledCobalt = List<String>.from(_cobaltInstances)..shuffle();
    final instancesToTry = shuffledCobalt.take(3);

    for (final instance in instancesToTry) {
      try {
        final uri = Uri.parse(instance);
        final origin = '${uri.scheme}://${uri.host}';

        debugPrint('YouTubeAudioService: Attempting Cobalt with $instance');

        Response? response;
        try {
          response = await _dio.post(
            instance,
            data: {
              'url': 'https://www.youtube.com/watch?v=$videoId',
              'audioOnly': true,
              'audioFormat': 'mp3',
            },
            options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Origin': origin,
                'Referer': '$origin/',
              },
            ),
          );
        } catch (e) {
          debugPrint('YouTubeAudioService: Cobalt initial request error: $e');
        }

        if (response == null ||
            response.statusCode == null ||
            response.statusCode! >= 400 ||
            response.statusCode == 526) {
          debugPrint(
            'YouTubeAudioService: Cobalt direct failed, trying via proxy...',
          );
          final proxyUrl =
              'https://corsproxy.io/?${Uri.encodeComponent(instance)}';
          response = await _dio.post(
            proxyUrl,
            data: {
              'url': 'https://www.youtube.com/watch?v=$videoId',
              'audioOnly': true,
              'audioFormat': 'mp3',
            },
            options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Origin': origin,
                'Referer': '$origin/',
              },
            ),
          );
        }

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final data = response.data;
          if (data is Map) {
            final status = data['status'];
            if (status == 'stream' ||
                status == 'redirect' ||
                status == 'tunnel') {
              return data['url']?.toString();
            } else {
              debugPrint(
                'YouTubeAudioService: Cobalt returned non-success status: $status',
              );
            }
          }
        } else {
          debugPrint(
            'YouTubeAudioService: Cobalt returned error status ${response.statusCode} from $instance',
          );
        }
      } catch (e) {
        debugPrint('YouTubeAudioService: Cobalt error with $instance: $e');
      }
    }
    return null;
  }

  /// Extraction using Muxiv (Muxed) API
  Future<String?> _getMuxivStreamUrl(String videoId) async {
    try {
      debugPrint('YouTubeAudioService: Attempting Muxiv with $videoId');
      final endpoint = 'https://api.muxiv.com/youtube/info?id=$videoId';

      Response? response;
      try {
        response = await _dio.get(
          endpoint,
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ),
        );
      } catch (e) {
        debugPrint('YouTubeAudioService: Muxiv direct failed with error: $e');
      }

      // If connection fails on Wi-Fi, try via Proxy
      if (response == null ||
          response.statusCode == null ||
          response.statusCode! >= 400) {
        debugPrint(
          'YouTubeAudioService: Muxiv direct failed, trying via proxy...',
        );
        final proxyUrl =
            'https://api.allorigins.win/raw?url=${Uri.encodeComponent(endpoint)}';
        response = await _dio.get(proxyUrl);
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;
        if (data != null && data is Map) {
          if (data['url'] != null) return data['url'].toString();
          final links = data['links'];
          if (links is List && links.isNotEmpty) {
            final first = links[0];
            if (first is Map && first['url'] != null) {
              return first['url'].toString();
            }
          }
        }
      } else {
        debugPrint(
          'YouTubeAudioService: Muxiv returned error status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('YouTubeAudioService: Muxiv error: $e');
    }
    return null;
  }

  /// Fallback stream extraction using Piped/Invidious API
  Future<String?> _getFallbackStreamUrl(String videoId) async {
    final shuffledInstances = List<String>.from(_fallbackInstances)..shuffle();
    final instancesToTry = shuffledInstances.take(3);

    for (final instance in instancesToTry) {
      try {
        debugPrint('YouTubeAudioService: Attempting fallback with $instance');

        final isPiped = instance.contains('piped');
        final endpoint = isPiped
            ? '$instance/streams/$videoId'
            : '$instance/videos/$videoId';

        Response? response;
        try {
          response = await _dio.get(
            endpoint,
            options: Options(
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
              },
            ),
          );
        } catch (e) {
          debugPrint(
            'YouTubeAudioService: Fallback direct request error with $instance: $e',
          );
        }

        // If connection fails or returns 0/404/etc on Wi-Fi, try via Proxy
        if (response == null ||
            response.statusCode == null ||
            response.statusCode! >= 400) {
          debugPrint(
            'YouTubeAudioService: Direct failed ($instance), trying via proxy...',
          );
          final proxyUrl =
              'https://api.allorigins.win/raw?url=${Uri.encodeComponent(endpoint)}';
          response = await _dio.get(proxyUrl);
        }

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final data = response.data;
          if (data == null || data is! Map) {
            debugPrint(
              'YouTubeAudioService: Fallback data is not a Map from $instance',
            );
            continue;
          }

          if (isPiped) {
            final audioStreams = data['audioStreams'];
            if (audioStreams is List && audioStreams.isNotEmpty) {
              try {
                final bestStream = audioStreams.firstWhere(
                  (s) =>
                      s is Map &&
                      (s['format'] as String?).toString().toLowerCase() ==
                          'm4a',
                  orElse: () => audioStreams.firstWhere(
                    (s) => s is Map,
                    orElse: () => null,
                  ),
                );
                if (bestStream != null &&
                    bestStream is Map &&
                    bestStream['url'] != null) {
                  return bestStream['url'].toString();
                }
              } catch (e) {
                debugPrint(
                  'YouTubeAudioService: Piped stream parsing error: $e',
                );
              }
            }
          } else {
            // Invidious format - handle both adaptiveFormats and formatStreams
            final adaptiveFormats = data['adaptiveFormats'];
            if (adaptiveFormats is List) {
              for (var format in adaptiveFormats) {
                if (format is! Map) continue;
                final type = (format['type'] as String?)
                    .toString()
                    .toLowerCase();
                if (type.contains('audio')) {
                  final url = format['url']?.toString();
                  if (url != null) return url;
                }
              }
            }

            // Try formatStreams if adaptive failed
            final formatStreams = data['formatStreams'];
            if (formatStreams is List && formatStreams.isNotEmpty) {
              for (var stream in formatStreams) {
                if (stream is Map && stream['url'] != null) {
                  return stream['url'].toString();
                }
              }
            }
          }
        } else {
          debugPrint(
            'YouTubeAudioService: Fallback returned error status ${response.statusCode} from $instance',
          );
        }
      } catch (e) {
        debugPrint('YouTubeAudioService: Fallback error with $instance: $e');
        continue;
      }
    }
    return null;
  }

  /// Get video metadata (title, duration, thumbnail, etc.)
  Future<YouTubeVideoInfo?> getVideoInfo(String videoIdOrUrl) async {
    final videoId = extractVideoId(videoIdOrUrl);
    if (videoId == null) return null;

    try {
      final video = await _youtube.videos.get(videoId);

      String? authorImageUrl;
      try {
        final channel = await _youtube.channels.get(video.channelId);
        authorImageUrl = channel.logoUrl;
      } catch (e) {
        debugPrint('YouTubeAudioService: Error getting channel info: $e');
      }

      return YouTubeVideoInfo(
        id: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration ?? Duration.zero,
        thumbnailUrl: video.thumbnails.highResUrl,
        description: video.description,
        authorImageUrl: authorImageUrl,
      );
    } catch (e) {
      debugPrint(
        'YouTubeAudioService: Error getting video info from YT, trying fallback: $e',
      );
      return await _getFallbackVideoInfo(videoId);
    }
  }

  /// Fallback video info extraction using Piped API
  Future<YouTubeVideoInfo?> _getFallbackVideoInfo(String videoId) async {
    final shuffledInstances = List<String>.from(_fallbackInstances)..shuffle();
    for (final instance in shuffledInstances) {
      try {
        debugPrint(
          'YouTubeAudioService: Attempting fallback info with $instance',
        );

        final isPiped = instance.contains('piped');
        final endpoint = isPiped
            ? '$instance/streams/$videoId'
            : '$instance/videos/$videoId';

        final response = await _dio.get(endpoint);

        if (response.statusCode == 200) {
          final data = response.data;
          if (data == null || data is! Map) continue;

          if (isPiped) {
            return YouTubeVideoInfo(
              id: videoId,
              title: (data['title'] ?? 'Unknown Title').toString(),
              author: (data['uploader'] ?? 'Unknown Author').toString(),
              duration: Duration(
                seconds: data['duration'] is int ? data['duration'] : 0,
              ),
              thumbnailUrl: (data['thumbnailUrl'] ?? '').toString(),
              description: (data['description'] ?? '').toString(),
              authorImageUrl: data['uploaderAvatar']?.toString(),
            );
          } else {
            // Invidious format
            String? thumb;
            final thumbs = data['videoThumbnails'];
            if (thumbs is List && thumbs.isNotEmpty) {
              final first = thumbs.first;
              if (first is Map) thumb = first['url']?.toString();
            }

            String? avatar;
            final avatars = data['authorThumbnails'];
            if (avatars is List && avatars.isNotEmpty) {
              final first = avatars.first;
              if (first is Map) avatar = first['url']?.toString();
            }

            return YouTubeVideoInfo(
              id: videoId,
              title: (data['title'] ?? 'Unknown Title').toString(),
              author: (data['author'] ?? 'Unknown Author').toString(),
              duration: Duration(
                seconds: data['lengthSeconds'] is int
                    ? data['lengthSeconds']
                    : 0,
              ),
              thumbnailUrl: thumb ?? '',
              description: (data['description'] ?? '').toString(),
              authorImageUrl: avatar,
            );
          }
        }
      } catch (e) {
        debugPrint(
          'YouTubeAudioService: Fallback info error with $instance: $e',
        );
        continue;
      }
    }
    return null;
  }

  /// Fallback playlist info extraction using Piped API
  Future<YouTubePlaylistInfo?> _getFallbackPlaylistInfo(
    String playlistId,
  ) async {
    final shuffledInstances = List<String>.from(_fallbackInstances)..shuffle();
    for (final instance in shuffledInstances) {
      if (!instance.contains('piped'))
        continue; // Currently only Piped fallback for playlists
      try {
        debugPrint(
          'YouTubeAudioService: Attempting fallback playlist info with $instance',
        );
        final response = await _dio.get('$instance/playlists/$playlistId');

        if (response.statusCode == 200) {
          final data = response.data;
          if (data == null || data is! Map) continue;

          return YouTubePlaylistInfo(
            id: playlistId,
            title: (data['name'] ?? 'Unknown Playlist').toString(),
            author: (data['uploader'] ?? 'Unknown Author').toString(),
            description: (data['description'] ?? '').toString(),
            thumbnailUrl: (data['thumbnailUrl'] ?? '').toString(),
            authorImageUrl: data['uploaderAvatar']?.toString(),
          );
        }
      } catch (e) {
        debugPrint(
          'YouTubeAudioService: Fallback playlist info error with $instance: $e',
        );
        continue;
      }
    }
    return null;
  }

  /// Get playlist metadata
  Future<YouTubePlaylistInfo?> getPlaylistInfo(String playlistUrl) async {
    try {
      final playlistId = PlaylistId.parsePlaylistId(playlistUrl);
      if (playlistId == null) return null;

      final playlist = await _youtube.playlists.get(playlistId);

      String? authorImageUrl;
      try {
        if (playlist.author.isNotEmpty) {
          // This is a workaround as playlist channelId is not directly exposed
          // Sometimes author is channel name. Searching for channels might work, or get first video channel.
          final videos = await _youtube.playlists
              .getVideos(playlistId)
              .take(1)
              .toList();
          if (videos.isNotEmpty) {
            final channel = await _youtube.channels.get(videos.first.channelId);
            authorImageUrl = channel.logoUrl;
          }
        }
      } catch (e) {
        debugPrint(
          'YouTubeAudioService: Error getting channel info for playlist: $e',
        );
      }

      return YouTubePlaylistInfo(
        id: playlist.id.value,
        title: playlist.title,
        author: playlist.author,
        description: playlist.description,
        thumbnailUrl: playlist.thumbnails.highResUrl,
        authorImageUrl: authorImageUrl,
      );
    } catch (e) {
      debugPrint(
        'YouTubeAudioService: Error getting playlist info from YT, trying fallback: $e',
      );
      final playlistId = PlaylistId.parsePlaylistId(playlistUrl);
      if (playlistId != null) {
        return await _getFallbackPlaylistInfo(playlistId.toString());
      }
      return null;
    }
  }

  /// Get all videos in a playlist
  Future<List<YouTubeVideoInfo>> getPlaylistVideos(String playlistUrl) async {
    try {
      final playlistId = PlaylistId.parsePlaylistId(playlistUrl);
      if (playlistId == null) return [];

      final videos = <YouTubeVideoInfo>[];
      await for (final video in _youtube.playlists.getVideos(playlistId)) {
        videos.add(
          YouTubeVideoInfo(
            id: video.id.value,
            title: video.title,
            author: video.author,
            duration: video.duration ?? Duration.zero,
            thumbnailUrl: video.thumbnails.highResUrl,
            description: video.description,
          ),
        );
      }
      return videos;
    } catch (e) {
      debugPrint(
        'YouTubeAudioService: Error getting playlist videos from YT, trying fallback: $e',
      );
      final playlistId = PlaylistId.parsePlaylistId(playlistUrl);
      if (playlistId != null) {
        return await _getFallbackPlaylistVideos(playlistId.toString());
      }
      return [];
    }
  }

  /// Fallback playlist videos extraction using Piped API
  Future<List<YouTubeVideoInfo>> _getFallbackPlaylistVideos(
    String playlistId,
  ) async {
    final shuffledInstances = List<String>.from(_fallbackInstances)..shuffle();
    for (final instance in shuffledInstances) {
      if (!instance.contains('piped'))
        continue; // Currently only Piped fallback for playlists
      try {
        debugPrint(
          'YouTubeAudioService: Attempting fallback playlist videos with $instance',
        );
        final response = await _dio.get('$instance/playlists/$playlistId');

        if (response.statusCode == 200) {
          final data = response.data;
          final relatedStreams = data['relatedStreams'] as List?;
          if (relatedStreams != null) {
            return relatedStreams.map((v) {
              final url = v['url'] as String? ?? '';
              final id = extractVideoId(url) ?? '';
              return YouTubeVideoInfo(
                id: id,
                title: v['title'] ?? 'Unknown Title',
                author: v['uploaderName'] ?? 'Unknown Author',
                duration: Duration(seconds: v['duration'] ?? 0),
                thumbnailUrl: v['thumbnail'] ?? '',
                description: '',
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint(
          'YouTubeAudioService: Fallback playlist videos error with $instance: $e',
        );
        continue;
      }
    }
    return [];
  }

  /// Search for long-form content (potential audiobooks)
  Future<List<YouTubeVideoInfo>> searchLongFormContent(String query) async {
    try {
      final searchResult = await _youtube.search.search(
        query,
        filter: TypeFilters.video,
      );

      return searchResult
          .where(
            (v) => (v.duration?.inMinutes ?? 0) > 20,
          ) // Long form > 20 mins
          .map(
            (v) => YouTubeVideoInfo(
              id: v.id.value,
              title: v.title,
              author: v.author,
              duration: v.duration ?? Duration.zero,
              thumbnailUrl: v.thumbnails.highResUrl,
              description: v.description,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('YouTubeAudioService: Search error: $e');
      return [];
    }
  }

  /// Clear the URL cache
  void clearCache() {
    _urlCache.clear();
  }

  /// Dispose resources
  void dispose() {
    _youtube.close();
    _urlCache.clear();
  }
}

class _CachedUrl {
  final String url;
  final DateTime timestamp;

  _CachedUrl(this.url, this.timestamp);

  bool get isExpired =>
      DateTime.now().difference(timestamp) >
      YouTubeAudioService._cacheValidityDuration;
}

/// Basic info about a YouTube video
class YouTubeVideoInfo {
  final String id;
  final String title;
  final String author;
  final Duration duration;
  final String thumbnailUrl;
  final String description;
  final String? authorImageUrl;

  YouTubeVideoInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    required this.description,
    this.authorImageUrl,
  });
}

/// Basic info about a YouTube playlist
class YouTubePlaylistInfo {
  final String id;
  final String title;
  final String author;
  final String description;
  final String thumbnailUrl;
  final String? authorImageUrl;

  YouTubePlaylistInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.thumbnailUrl,
    this.authorImageUrl,
  });
}
