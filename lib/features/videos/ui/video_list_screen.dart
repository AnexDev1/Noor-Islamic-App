import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final yt.Video? videoInfo;
  final List<yt.Video>? relatedVideos;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.videoInfo,
    this.relatedVideos,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _showControls = true;
  bool _isDescriptionExpanded = false;
  final ScrollController _scrollController = ScrollController();

  // Lazy metadata fetch when videoInfo is not provided
  final _yt = yt.YoutubeExplode();
  yt.Video? _fetchedVideo;

  // Related videos fallback when none are supplied by caller
  List<yt.Video> _related = [];
  bool _loadingRelated = false;
  bool _loadingRelatedMore = false; // background fetch indicator

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_listener);

    // If full metadata isn't provided, fetch it lazily
    if (widget.videoInfo == null) {
      _fetchMetadata();
    }
  }

  bool _wasFullScreen = false;

  void _listener() {
    final isFull = _controller.value.isFullScreen;
    if (isFull != _wasFullScreen) {
      _wasFullScreen = isFull;
      if (isFull) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }

    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  Future<void> _fetchMetadata() async {
    try {
      final vid = await _yt.videos.get(widget.videoId);
      if (mounted) {
        setState(() => _fetchedVideo = vid);
      }
      // After fetching metadata, ensure related videos are fetched if needed
      _ensureRelated();
    } catch (e) {
      debugPrint('Failed to fetch video metadata: $e');
    }
  }

  void _ensureRelated() {
    // If host provided related videos, use them as an initial placeholder but
    // still fetch channel uploads (they are preferred) to ensure the related
    // list matches the currently playing video's channel.
    if (widget.relatedVideos != null && widget.relatedVideos!.isNotEmpty) {
      setState(() => _related = widget.relatedVideos!);
      if (!_loadingRelated) {
        _fetchRelatedVideos();
      }
      return;
    }

    if (_related.isEmpty && !_loadingRelated) {
      _fetchRelatedVideos();
    }
  }

  Future<void> _fetchRelatedVideos() async {
    final current = _fetchedVideo ?? widget.videoInfo;
    if (current == null) return;

    setState(() => _loadingRelated = true);
    final String currentId = widget.videoId.trim();

    String? channelId;

    // Try to extract a channel id from runtime fields using dynamic access.
    try {
      final dyn = current as dynamic;

      // Common property: authorUrl (may contain /channel/{id} or /@handle)
      try {
        final String? authorUrl = dyn.authorUrl as String?;
        if (authorUrl != null && authorUrl.isNotEmpty) {
          final m = RegExp(r'/channel/([A-Za-z0-9_-]+)').firstMatch(authorUrl);
          if (m != null) {
            channelId = m.group(1);
          } else {
            // Try handle fallback (e.g., /@handle)
            final h = RegExp(r'/(@[^/?]+)').firstMatch(authorUrl);
            if (h != null) {
              final handle = h.group(1)!.replaceFirst('@', '');
              try {
                final channel = await _yt.channels.getByHandle(handle);
                channelId = channel.id.value;
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // Try other possible fields (authorId, channelId, owner)
      try {
        final dynamic candidate = dyn.authorId ?? dyn.channelId ?? dyn.owner;
        if (candidate != null) {
          channelId ??= candidate is String ? candidate : candidate.toString();
        }
      } catch (_) {}
    } catch (_) {}

    // If we found a channel id, fetch the channel uploads
    if (channelId != null) {
      try {
        final uploads = await _yt.channels
            .getUploads(yt.ChannelId(channelId))
            .take(10)
            .toList();
        final filtered = uploads
            .where((v) => v.id.value.toString().trim() != currentId)
            .toList();
        if (mounted) {
          setState(() {
            _related = filtered;
            _loadingRelated = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('Failed to fetch channel uploads ($channelId): $e');
      }
    }

    // Fallback: search for other videos by the same author name
    final authorName = (current.author ?? '').trim();
    final List<yt.Video> results = [];
    if (authorName.isNotEmpty) {
      try {
        final searchList = await _yt.search.search(authorName);
        for (final item in searchList) {
          try {
            final id = (item.id?.value ?? item.id.toString()).toString().trim();
            if (id == currentId) continue;
            final v = await _yt.videos.get(id);
            if (v.author == authorName) {
              results.add(v);
              if (results.length >= 8) break;
            }
          } catch (_) {
            // ignore individual failures
          }
        }
      } catch (e) {
        debugPrint('Fallback search for author failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _related = results;
        _loadingRelated = false;
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    _scrollController.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.accent,
        progressColors: ProgressBarColors(
          playedColor: AppColors.accent,
          handleColor: AppColors.accent,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade400,
        ),
        onReady: () {
          setState(() => _isPlayerReady = true);
        },
        onEnded: (data) {
          // Auto play next video or show suggestions
        },
        topActions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Video Player
                player,

                // Content below player
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F0F0F)
                          : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(0),
                      ),
                    ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Video Info Section
                        SliverToBoxAdapter(child: _buildVideoInfoSection()),

                        // Description
                        if ((_fetchedVideo?.description ??
                                widget.videoInfo?.description) !=
                            null)
                          SliverToBoxAdapter(child: _buildDescriptionSection()),

                        // Related Videos (from caller or fallback search)
                        if ((widget.relatedVideos != null &&
                                widget.relatedVideos!.isNotEmpty) ||
                            _related.isNotEmpty ||
                            _loadingRelated)
                          SliverToBoxAdapter(
                            child: _buildRelatedVideosSection(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _fetchedVideo?.title ?? widget.videoInfo?.title ?? 'Islamic Video',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Date only (views removed)
          Text(
            widget.videoInfo != null
                ? _formatDate(widget.videoInfo!.uploadDate)
                : 'Islamic Content',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Channel Info with inline share icon
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.videoInfo?.author ?? 'Islamic Channel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Share icon placed beside channel name (icon-only)
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () =>
                    _showShareSheetForVideo(_fetchedVideo ?? widget.videoInfo),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: _buildEngagementButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {
            // Share functionality
          },
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final description =
        _fetchedVideo?.description ?? widget.videoInfo?.description ?? '';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (description.length > 150)
            TextButton(
              onPressed: () {
                setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                );
              },
              child: Text(
                _isDescriptionExpanded ? 'Show less' : 'Show more',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideosSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final list =
        (widget.relatedVideos != null && widget.relatedVideos!.isNotEmpty)
        ? widget.relatedVideos!
        : _related;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Related Videos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        // If initial load is ongoing and nothing to show yet, show spinner
        if (_loadingRelated && list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No related videos available',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          )
        else
          Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final video = list[index];
                  return _buildRelatedVideoItem(video, isDark);
                },
              ),
              // Background fetch indicator
              if (_loadingRelatedMore)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRelatedVideoItem(yt.Video video, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoId: video.id.value,
              videoInfo: video,
              relatedVideos:
                  null, // force the player to fetch channel uploads for this video
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image.network(
                    video.thumbnails.mediumResUrl,
                    width: 160,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 160,
                      height: 90,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  if (video.duration != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Video Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatViewCount(video.engagement.viewCount)} • ${_formatDate(video.uploadDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // More options
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  // Share sheet similar to Shorts viewer
  void _showShareSheetForVideo(yt.Video? v) {
    final id = (v?.id.value ?? '').toString().trim();
    if (id.isEmpty) return;
    final url = 'https://www.youtube.com/watch?v=${Uri.encodeComponent(id)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Share to',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.link_rounded, 'Copy Link', () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  }
                }),
                _buildShareOption(Icons.share_rounded, 'Share', () async {
                  try {
                    await Share.share(url);
                  } catch (e) {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    }
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                }),
                _buildShareOption(Icons.open_in_new_rounded, 'Open', () async {
                  try {
                    await launchUrlString(url);
                  } catch (_) {}
                  if (mounted) Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    if (duration.inHours > 0) {
      return '${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }
}

// Shimmer Widget for Loading State
class _ShimmerWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;

  const _ShimmerWidget({
    this.width,
    this.height,
    this.borderRadius = 8,
    required this.isDark,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      Colors.grey.shade900,
                      Colors.grey.shade800,
                      Colors.grey.shade900,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}
