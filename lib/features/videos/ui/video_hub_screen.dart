import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/video_item.dart';
import 'shorts_viewer_screen.dart';
import 'video_list_screen.dart';

/// Premium Video Hub with immersive UX
class VideoHubScreen extends StatefulWidget {
  final List<String> channelIds;

  const VideoHubScreen({super.key, required this.channelIds});

  @override
  State<VideoHubScreen> createState() => _VideoHubScreenState();
}

class _VideoHubScreenState extends State<VideoHubScreen>
    with TickerProviderStateMixin {
  final _yt = yt.YoutubeExplode();
  List<VideoItem> _videos = [];
  List<VideoItem> _filteredVideos = [];
  List<VideoItem> _shorts = [];
  Map<String, String> _channelNames = {};
  bool _loading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;

  // Incremental loading configuration
  final int _initialPerChannel = 6; // fetch small batch first
  final int _backgroundPerChannel = 20; // fetch additional items in background
  bool _isBackgroundLoading = false;

  late AnimationController _animationController;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Track seen IDs to avoid duplicates during fetches
  final Set<String> _seenIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    // Defer fetch until after first frame so NestedScrollView + TabBarView
    // complete their initial layout (fixes content not showing on first load)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchContent();
    });
  }

  Future<void> _fetchContent() async {
    // Load cached videos if available so user sees results immediately
    await _loadCache();

    if (mounted) {
      setState(() {
        _loading = _videos.isEmpty; // show loading only if we have no cache
        _isBackgroundLoading = true;
      });
    }

    // Use class-level seen set to prevent duplicates across both fetch phases
    _seenIds.clear();
    _seenIds.addAll(_videos.map((v) => v.id));
    _seenIds.addAll(_shorts.map((s) => s.id));

    // Fetch channels and update UI progressively as each completes
    final List<VideoItem> allVideos = [];
    final List<VideoItem> allShorts = [];
    final Map<String, String> channelNames = {};

    // Launch all fetches but process results as they arrive
    final futures = widget.channelIds.map((channelId) async {
      final result = await _fetchChannelBatch(channelId);
      if (result != null && mounted) {
        // Process this channel's results immediately
        channelNames[result.channelId] = result.channelName;
        for (final item in result.videos) {
          if (!_seenIds.contains(item.id)) {
            _seenIds.add(item.id);
            allVideos.add(item);
          }
        }
        for (final item in result.shorts) {
          if (!_seenIds.contains(item.id)) {
            _seenIds.add(item.id);
            allShorts.add(item);
          }
        }

        // Update UI immediately with current results
        setState(() {
          _videos = List.from(allVideos);
          _shorts = List.from(allShorts);
          _filteredVideos = _videos;
          _channelNames = Map.from(channelNames);
          _loading = false;
        });
      }
      return result;
    }).toList();

    // Wait for all to complete (with individual timeouts handled in _fetchChannelBatch)
    await Future.wait(futures, eagerError: false);

    // Final sort by popularity after all channels loaded
    if (mounted && allVideos.isNotEmpty) {
      final sortedByPopularity = List<VideoItem>.from(allVideos)
        ..sort((a, b) {
          final av = a.viewCount ?? 0;
          final bv = b.viewCount ?? 0;
          if (bv != av) return bv.compareTo(av);
          final al = a.likeCount ?? 0;
          final bl = b.likeCount ?? 0;
          return bl.compareTo(al);
        });

      const int topN = 10;
      final topPopular = sortedByPopularity.take(topN).toList();
      final rest = allVideos
          .where((v) => !topPopular.any((t) => t.id == v.id))
          .toList();

      final finalList = List<VideoItem>.from(topPopular)..addAll(rest);

      setState(() {
        _videos = List.from(finalList);
        _filteredVideos = _videos;
        _loading = false;
      });
      await _saveCache();
    }

    // Ensure loading is false even if no videos found
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    // Background-load more items per channel
    _backgroundLoadRemaining();

    if (mounted) _animationController.forward();
  }

  /// Fetches initial batch for a single channel with timeout. Returns (channelId, channelName, videos, shorts) or null on error.
  Future<
    ({
      String channelId,
      String channelName,
      List<VideoItem> videos,
      List<VideoItem> shorts,
    })?
  >
  _fetchChannelBatch(String channelId) async {
    try {
      final id = yt.ChannelId(channelId);

      // Add timeout to prevent hanging on slow/unresponsive channels
      final channelInfo = await _yt.channels
          .get(id)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Channel info timeout'),
          );

      final initialUploads = await _yt.channels
          .getUploads(id)
          .take(_initialPerChannel)
          .toList()
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw Exception('Uploads fetch timeout'),
          );

      final videos = <VideoItem>[];
      final shorts = <VideoItem>[];

      for (final video in initialUploads) {
        final item = VideoItem.fromYt(video);
        if (video.duration != null &&
            video.duration!.inSeconds <= 60 &&
            video.duration!.inSeconds >= 10) {
          shorts.add(item);
        } else {
          videos.add(item);
        }
      }

      return (
        channelId: channelId,
        channelName: channelInfo.title,
        videos: videos,
        shorts: shorts,
      );
    } catch (e) {
      debugPrint('Error fetching channel $channelId: $e');
      return null;
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_videos',
        jsonEncode(_videos.map((v) => v.toMap()).toList()),
      );
      await prefs.setString(
        'cached_shorts',
        jsonEncode(_shorts.map((v) => v.toMap()).toList()),
      );
      await prefs.setString('cached_channel_names', jsonEncode(_channelNames));
      await prefs.setInt(
        'cached_videos_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cv = prefs.getString('cached_videos');
      final cs = prefs.getString('cached_shorts');
      final cn = prefs.getString('cached_channel_names');

      if (cv != null) {
        final list = jsonDecode(cv) as List<dynamic>;
        _videos = list
            .map((e) => VideoItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _filteredVideos = List.from(_videos);
      }

      if (cs != null) {
        final list = jsonDecode(cs) as List<dynamic>;
        _shorts = list
            .map((e) => VideoItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (cn != null) {
        final map = Map<String, dynamic>.from(jsonDecode(cn));
        _channelNames = map.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
  }

  Future<void> _backgroundLoadRemaining() async {
    setState(() => _isBackgroundLoading = true);

    for (final channelId in widget.channelIds) {
      try {
        final id = yt.ChannelId(channelId);

        // Fetch a larger chunk (initial + background) and append the remainder
        final combined = await _yt.channels
            .getUploads(id)
            .take(_initialPerChannel + _backgroundPerChannel)
            .toList();

        if (combined.length > _initialPerChannel) {
          final remaining = combined.skip(_initialPerChannel).toList();

          // Add remaining items to lists (append at end, no shuffle)
          for (final video in remaining) {
            final item = VideoItem.fromYt(video);
            if (_seenIds.contains(item.id)) continue;
            _seenIds.add(item.id);

            if (video.duration != null &&
                video.duration!.inSeconds <= 60 &&
                video.duration!.inSeconds >= 10) {
              _shorts.add(item);
            } else {
              _videos.add(item);
            }
          }

          // Update UI after appending more
          if (mounted) {
            setState(() {
              _filteredVideos = _videos;
            });
            await _saveCache();
          }
        }
      } catch (e) {
        debugPrint('Error background-loading channel $channelId: $e');
      }
    }

    if (mounted) setState(() => _isBackgroundLoading = false);
  }

  void _filterVideos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _applyChannelFilter();
      } else {
        final searchFiltered = _videos.where((video) {
          final title = video.title.toLowerCase();
          final author = video.author.toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || author.contains(searchLower);
        }).toList();

        if (_selectedFilter == 'All') {
          _filteredVideos = searchFiltered;
        } else {
          _filteredVideos = searchFiltered
              .where((video) => video.author == _selectedFilter)
              .toList();
        }
      }
    });
  }

  void _applyChannelFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredVideos = _videos;
      } else {
        _filteredVideos = _videos
            .where((video) => video.author == _selectedFilter)
            .toList();
      }
    });
  }

  void _openShortsViewer(int startIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ShortsViewerScreen(
              channelIds: widget.channelIds,
              startIndex: startIndex,
              preloadedShorts: _shorts,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
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
  }

  @override
  void dispose() {
    _yt.close();
    _animationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      body: NestedScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildPremiumAppBar(isDark, size),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Videos tab
            CustomScrollView(
              slivers: [
                if (_loading)
                  _buildLoadingState(isDark)
                else if (_filteredVideos.isEmpty)
                  _buildEmptyState(isDark)
                else
                  _buildVideoGrid(isDark),
              ],
            ),
            // Shorts tab
            _buildShortsPreviewTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumAppBar(bool isDark, Size size) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_tabController.index == 0)
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      key: ValueKey(_isSearching),
                      color: isDark ? Colors.white : Colors.black87,
                      size: 22,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _filterVideos('');
                      }
                    });
                    if (_isSearching) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _searchFocusNode.requestFocus();
                      });
                    }
                  },
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A2E)]
                  : [const Color(0xFFF8F9FA), const Color(0xFFE8EAF6)],
            ),
          ),
          child: SafeArea(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 60, 20, 0)),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(
          56 + 44 + (_isBackgroundLoading ? 4 : 0),
        ),
        child: Column(
          children: [
            _buildTabBar(isDark),
            if (_isBackgroundLoading)
              const SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            SizedBox(
              height: 44,
              child: _tabController.index == 0
                  ? (_isSearching
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                            child: _buildSearchBar(isDark),
                          )
                        : Container(
                            // margin: const EdgeInsets.only(top: 8),
                            child: _buildFilterChips(isDark),
                          ))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search videos, channels...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterVideos('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 4,
          ),
        ),
        onChanged: _filterVideos,
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', ..._channelNames.values];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filters.length,
      itemBuilder: (context, index) {
        final filter = filters[index];
        final isSelected = _selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _applyChannelFilter();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(bool isDark) {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: isDark
          ? Colors.grey.shade400
          : Colors.grey.shade600,
      tabs: const [
        Tab(icon: Icon(Icons.play_circle_outline), text: 'Videos'),
        Tab(icon: Icon(Icons.bolt), text: 'Shorts'),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerCard(isDark, index),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 48,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No videos available' : 'No results found',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Check back later for new content'
                  : 'Try a different search term',
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortsPreviewTab(bool isDark) {
    if (_shorts.isEmpty) {
      return _buildEmptyShortsState(isDark);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _shorts.length,
      itemBuilder: (context, index) =>
          _buildShortPreviewCard(_shorts[index], index, isDark),
    );
  }

  Widget _buildShortPreviewCard(VideoItem short, int index, bool isDark) {
    return GestureDetector(
      onTap: () => _openShortsViewer(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              short.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                child: Icon(
                  Icons.play_circle_outline,
                  size: 32,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      short.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      short.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyShortsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: 48,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No shorts available',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new content',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final video = _filteredVideos[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildPremiumVideoCard(video, isDark, index),
          );
        }, childCount: _filteredVideos.length),
      ),
    );
  }

  Widget _buildPremiumVideoCard(VideoItem video, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  VideoPlayerScreen(
                    videoId: video.id,
                    videoInfo: null, // fetch metadata in player if needed
                    relatedVideos: null,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    );
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 48,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                          // Play button overlay
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Duration badge
                  if (video.durationSeconds != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDurationFromSeconds(video.durationSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Video Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel row
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.accent.withValues(alpha: 0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              video.author.isNotEmpty
                                  ? video.author[0].toUpperCase()
                                  : 'I',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Islamic Channel',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // More button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Title
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Stats row
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.visibility_outlined,
                          _formatViewCount(video.viewCount ?? 0),
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          Icons.schedule_outlined,
                          _formatDate(video.uploadDate),
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 60,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationFromSeconds(int? seconds) {
    if (seconds == null) return '';
    final duration = Duration(seconds: seconds);
    return _formatDuration(duration);
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
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }
}
