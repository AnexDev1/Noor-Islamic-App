import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../../../../core/theme/app_colors.dart';

/// Premium TikTok-style Shorts Viewer with immersive full-screen experience
class ShortsViewerScreen extends StatefulWidget {
  final List<String> channelIds;

  const ShortsViewerScreen({super.key, required this.channelIds});

  @override
  State<ShortsViewerScreen> createState() => _ShortsViewerScreenState();
}

class _ShortsViewerScreenState extends State<ShortsViewerScreen>
    with TickerProviderStateMixin {
  final _yt = yt.YoutubeExplode();
  List<yt.Video> _shorts = [];
  bool _loading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final Map<int, YoutubePlayerController> _controllers = {};
  final Map<int, bool> _liked = {};
  final Map<int, bool> _bookmarked = {};

  late AnimationController _heartAnimationController;
  late AnimationController _fadeController;
  bool _showDoubleTapHeart = false;
  bool _isPaused = false;
  Offset _heartPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Full immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fetchShorts();
  }

  Future<void> _fetchShorts() async {
    setState(() => _loading = true);
    List<yt.Video> allShorts = [];

    for (final channelId in widget.channelIds) {
      try {
        final id = yt.ChannelId(channelId);
        final uploads = await _yt.channels.getUploads(id).take(50).toList();

        // Filter for shorts (typically under 60 seconds)
        final shorts = uploads.where((video) {
          return video.duration != null &&
              video.duration!.inSeconds <= 60 &&
              video.duration!.inSeconds >= 10;
        }).toList();

        allShorts.addAll(shorts);
      } catch (e) {
        debugPrint('Error fetching shorts from channel $channelId: $e');
      }
    }

    if (mounted) {
      setState(() {
        _shorts = allShorts..shuffle();
        _loading = false;
      });

      if (_shorts.isNotEmpty) {
        _initializeController(0);
        // Preload next one
        if (_shorts.length > 1) {
          _initializeController(1);
        }
      }
    }
  }

  void _initializeController(int index) {
    if (_shorts.isEmpty) return;
    final logical = (index % _shorts.length + _shorts.length) % _shorts.length;
    if (_controllers.containsKey(logical)) return;

    final controller = YoutubePlayerController(
      initialVideoId: _shorts[logical].id.value,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        hideControls: true,
        controlsVisibleAtStart: false,
        disableDragSeek: true,
        showLiveFullscreenButton: false,
      ),
    );

    _controllers[logical] = controller;
  }

  void _disposeController(int index) {
    _controllers[index]?.dispose();
    _controllers.remove(index);
  }

  void _onPageChanged(int index) {
    if (_shorts.isEmpty) return;
    final logical = index % _shorts.length;

    // Pause previous video
    final prevController = _controllers[_currentIndex];
    prevController?.pause();

    setState(() {
      _currentIndex = logical;
      _isPaused = false;
    });

    // Play current video (logical key)
    final currentController = _controllers[logical];
    if (currentController != null) {
      currentController.play();
    } else {
      _initializeController(logical);
    }

    // Preload adjacent videos (modulo)
    _initializeController((logical + 1) % _shorts.length);
    _initializeController((logical - 1 + _shorts.length) % _shorts.length);

    // Keep only adjacent controllers to free memory
    final keep = {
      logical,
      (logical + 1) % _shorts.length,
      (logical - 1 + _shorts.length) % _shorts.length,
    };
    for (final key in _controllers.keys.toList()) {
      if (!keep.contains(key)) _disposeController(key);
    }
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller == null) return;

    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    setState(() {
      _liked[_currentIndex] = true;
      _showDoubleTapHeart = true;
      _heartPosition = details.localPosition;
    });

    _heartAnimationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _showDoubleTapHeart = false);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pageController.dispose();
    _heartAnimationController.dispose();
    _fadeController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingScreen();
    }

    if (_shorts.isEmpty) {
      return _buildEmptyScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-screen PageView for TikTok-style scrolling (infinite loop via modulo mapping)
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            onPageChanged: _onPageChanged,
            // No itemCount for infinite behavior; map to shorts via modulo
            itemBuilder: (context, index) {
              final logicalIndex = _shorts.isEmpty ? 0 : index % _shorts.length;
              return _buildShortItem(logicalIndex);
            },
          ),

          // Top gradient for status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar with back button
          SafeArea(child: _buildTopBar()),

          // Double tap heart animation
          if (_showDoubleTapHeart)
            Positioned(
              left: _heartPosition.dx - 50,
              top: _heartPosition.dy - 50,
              child: AnimatedBuilder(
                animation: _heartAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_heartAnimationController.value * 0.5),
                    child: Opacity(
                      opacity: 1.0 - _heartAnimationController.value,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom loading animation
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(bounds),
              child: const Text(
                'Loading Shorts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing immersive experience...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No shorts available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new content',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text(
                        'Go Back',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button with glassmorphism
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ).createShader(bounds),
            child: const Text(
              'Shorts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          // Video counter removed per design
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildShortItem(int index) {
    final short = _shorts[index];
    final controller = _controllers[index];
    final isLiked = _liked[index] ?? false;
    final isBookmarked = _bookmarked[index] ?? false;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTapDown: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player background
          Container(color: Colors.black),

          // Video player
          if (controller != null && index == _currentIndex)
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: false,
                  progressColors: ProgressBarColors(
                    playedColor: AppColors.primary,
                    handleColor: AppColors.primary,
                  ),
                  bottomActions: const [],
                  topActions: const [],
                ),
              ),
            )
          else
            // Thumbnail placeholder
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    short.thumbnails.highResUrl,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey.shade900),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Pause indicator
          if (_isPaused && index == _currentIndex)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

          // Bottom gradient for text visibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Right side action buttons (TikTok style)
          Positioned(
            right: 12,
            bottom: 140,
            child: Column(
              children: [
                // Like button with animation
                _buildAnimatedActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(short.engagement.likeCount ?? 0),
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() {
                      _liked[index] = !isLiked;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(height: 20),

                // Comment button
                _buildAnimatedActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _formatCount((short.engagement.likeCount ?? 0) ~/ 10),
                  onTap: () {
                    _showCommentsSheet(short);
                  },
                ),
                const SizedBox(height: 20),

                // Bookmark button
                _buildAnimatedActionButton(
                  icon: isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  label: 'Save',
                  color: isBookmarked ? AppColors.primary : Colors.white,
                  onTap: () {
                    setState(() {
                      _bookmarked[index] = !isBookmarked;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(height: 20),

                // Share button
                _buildAnimatedActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {
                    _showShareSheet(short);
                  },
                ),
                const SizedBox(height: 24),

                // Channel avatar
                GestureDetector(
                  onTap: () {},
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                short.author.isNotEmpty
                                    ? short.author[0].toUpperCase()
                                    : 'I',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Follow button
                      Positioned(
                        bottom: -6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.pink.shade400,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom info section
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel name with verified badge
                Row(
                  children: [
                    Text(
                      '@${short.author}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Video title
                Text(
                  short.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Music/sound indicator
                Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildMarqueeText(
                        'Original Sound - ${short.author}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress indicator at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildProgressIndicator(index),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarqueeText(String text) {
    return SizedBox(
      height: 20,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int index) {
    final controller = _controllers[index];
    if (controller == null) {
      return Container(height: 3, color: Colors.grey.shade800);
    }

    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        if (!controller.value.isReady) {
          return Container(height: 3, color: Colors.grey.shade800);
        }

        final position = controller.value.position;
        final duration = controller.metadata.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Container(
          height: 3,
          color: Colors.grey.shade800,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCommentsSheet(yt.Video short) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(yt.Video short) {
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
                _buildShareOption(Icons.link_rounded, 'Copy Link'),
                _buildShareOption(Icons.message_rounded, 'Message'),
                _buildShareOption(Icons.more_horiz_rounded, 'More'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
