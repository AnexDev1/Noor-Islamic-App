import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'shorts_viewer_screen.dart';

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

class VideoListScreen extends StatefulWidget {
  final List<String> channelIds;

  const VideoListScreen({super.key, required this.channelIds});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen>
    with SingleTickerProviderStateMixin {
  final _yt = yt.YoutubeExplode();
  List<yt.Video> _videos = [];
  List<yt.Video> _filteredVideos = [];
  Map<String, String> _channelNames = {};
  bool _loading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() => _loading = true);
    List<yt.Video> allVideos = [];
    Map<String, String> channelNames = {};

    // Fetch videos only from specified Islamic channel IDs
    for (final channelId in widget.channelIds) {
      try {
        // Accept channel ID, channel URL (contains /channel/), custom URL (/c/) or handle (contains @)
        late yt.ChannelId id;
        if (channelId.contains('/channel/')) {
          final part = channelId.split('/channel/').last;
          id = yt.ChannelId(part.split('?').first);
        } else if (channelId.contains('/c/')) {
          final part = channelId.split('/c/').last;
          final candidate = part.split('?').first.split('/').first;
          try {
            final channel = await _yt.channels.getByHandle(
              candidate.startsWith('@') ? candidate.substring(1) : candidate,
            );
            id = channel.id;
          } catch (_) {
            id = yt.ChannelId(candidate);
          }
        } else if (channelId.contains('/user/')) {
          final part = channelId.split('/user/').last;
          final candidate = part.split('?').first.split('/').first;
          try {
            final channel = await _yt.channels.getByHandle(
              candidate.startsWith('@') ? candidate.substring(1) : candidate,
            );
            id = channel.id;
          } catch (_) {
            id = yt.ChannelId(candidate);
          }
        } else if (channelId.contains('@')) {
          var handle = channelId.substring(channelId.indexOf('@') + 1);
          if (handle.contains('?')) handle = handle.split('?').first;
          if (handle.contains('/')) handle = handle.split('/').first;
          if (handle.startsWith('@')) handle = handle.substring(1);
          try {
            final channel = await _yt.channels.getByHandle(handle);
            id = channel.id;
          } catch (_) {
            id = yt.ChannelId(handle);
          }
        } else {
          id = yt.ChannelId(channelId.split('?').first);
        }

        // Fetch channel info to get the channel name
        final channelInfo = await _yt.channels.get(id);
        channelNames[channelId] = channelInfo.title;

        // Fetch from the specified Islamic channels - take up to 20 videos per channel
        final uploads = await _yt.channels.getUploads(id).take(20).toList();
        allVideos.addAll(uploads);
      } catch (e) {
        debugPrint('Error fetching Islamic channel $channelId: $e');
      }
    }

    if (mounted) {
      setState(() {
        // Shuffle for variety
        _videos = allVideos..shuffle();
        _filteredVideos = _videos;
        _channelNames = channelNames;
        _loading = false;
      });
      _animationController.forward();
    }
  }

  void _filterVideos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _applyChannelFilter();
      } else {
        // Apply search filter first, then channel filter
        final searchFiltered = _videos.where((video) {
          final title = video.title.toLowerCase();
          final author = video.author.toLowerCase();
          final description = video.description.toLowerCase();
          final searchLower = query.toLowerCase();

          return title.contains(searchLower) ||
              author.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();

        // Then apply channel filter if any
        if (_selectedFilter == 'All') {
          _filteredVideos = searchFiltered;
        } else {
          _filteredVideos = searchFiltered.where((video) {
            return video.author == _selectedFilter;
          }).toList();
        }
      }
    });
  }

  void _applyChannelFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredVideos = _videos;
      } else {
        _filteredVideos = _videos.where((video) {
          return video.author == _selectedFilter;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _yt.close();
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Modern App Bar with Search
            SliverAppBar(
              expandedHeight: _isSearching ? 120 : 160,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 56, bottom: 52),
                title: _isSearching
                    ? null
                    : Text(
                        'Islamic Videos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                background: Container(
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                ),
              ),
              actions: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearching
                      ? IconButton(
                          key: const ValueKey('close'),
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                              _filterVideos('');
                            });
                            _searchFocusNode.unfocus();
                          },
                        )
                      : IconButton(
                          key: const ValueKey('search'),
                          icon: Icon(
                            Icons.search,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            setState(() => _isSearching = true);
                            _searchFocusNode.requestFocus();
                          },
                        ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Column(
                  children: [
                    // Search Bar
                    if (_isSearching)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search videos...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: _filterVideos,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: CustomScrollView(
          slivers: [
            // Filter Chips
            SliverToBoxAdapter(child: _buildFilterChips(isDark)),

            // Video List or Loading
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(isDark),
                    childCount: 5,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final video = _filteredVideos[index];
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index /
                                    (_filteredVideos.isEmpty
                                        ? 1
                                        : _filteredVideos.length)) *
                                0.5,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  (index /
                                          (_filteredVideos.isEmpty
                                              ? 1
                                              : _filteredVideos.length)) *
                                      0.5,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                        child: _buildVideoCard(video, isDark),
                      ),
                    );
                  }, childCount: _filteredVideos.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ShortsViewerScreen(channelIds: widget.channelIds),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.play_circle_filled, color: Colors.white),
        label: const Text(
          'Shorts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showSearchDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(
          'Search Videos',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Search by title, channel, or keywords...',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (value) {
            _filterVideos(value);
          },
          onSubmitted: (value) {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _filterVideos('');
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    // Build filters list with 'All' and actual channel names
    final filters = ['All', ..._channelNames.values.toList()];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _applyChannelFilter();
                });
              },
              backgroundColor: isDark
                  ? Colors.grey.shade900
                  : Colors.grey.shade200,
              selectedColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(yt.Video video, bool isDark) {
    return InkWell(
      onTap: () {
        if (video.id.value.isEmpty) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                VideoPlayerScreen(
                  videoId: video.id.value,
                  videoInfo: video,
                  relatedVideos: _filteredVideos
                      .where((v) => v.id != video.id)
                      .take(10)
                      .toList(),
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video.thumbnails.highResUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay for better text visibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),

                // Duration Badge
                if (video.duration != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(video.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                // Play icon overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Video Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.35,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Channel and Stats Row
                  Row(
                    children: [
                      // Channel Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          video.author.isNotEmpty
                              ? video.author[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Channel name and stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.author,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatViewCount(video.engagement.viewCount)} • ${_formatDate(video.uploadDate)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // More options
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () {
                          _showVideoOptions(context, video, isDark);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail shimmer
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _ShimmerWidget(isDark: isDark),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerWidget(
                  isDark: isDark,
                  height: 16,
                  width: double.infinity,
                ),
                const SizedBox(height: 8),
                _ShimmerWidget(isDark: isDark, height: 16, width: 200),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ShimmerWidget(
                      isDark: isDark,
                      height: 32,
                      width: 32,
                      borderRadius: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerWidget(
                            isDark: isDark,
                            height: 12,
                            width: 120,
                          ),
                          const SizedBox(height: 6),
                          _ShimmerWidget(
                            isDark: isDark,
                            height: 10,
                            width: 150,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoOptions(BuildContext context, yt.Video video, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetOption(Icons.share_outlined, 'Share', isDark, () {
              Navigator.pop(context);
              // Share functionality
            }),
            _buildBottomSheetOption(
              Icons.download_outlined,
              'Download',
              isDark,
              () {
                Navigator.pop(context);
                // Download functionality
              },
            ),
            _buildBottomSheetOption(
              Icons.playlist_add,
              'Save to playlist',
              isDark,
              () {
                Navigator.pop(context);
                // Save to playlist
              },
            ),
            _buildBottomSheetOption(
              Icons.not_interested_outlined,
              'Not interested',
              isDark,
              () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
    IconData icon,
    String label,
    bool isDark,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
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
            Text(
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                }),
                _buildShareOption(Icons.share_rounded, 'Share', () async {
                  try {
                    await Share.share(url);
                  } catch (e) {
                    await Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  } finally {
                    Navigator.pop(context);
                  }
                }),
                _buildShareOption(Icons.open_in_new_rounded, 'Open', () async {
                  try {
                    await launchUrlString(url);
                  } catch (_) {}
                  Navigator.pop(context);
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
