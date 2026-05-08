import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:audio_service/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/youtube_audio_service.dart';
import '../../../core/services/global_audio_handler.dart';
import '../../quran/audio/quran_audio_handler.dart';
import '../domain/video_item.dart';

class YouTubeAudioPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const YouTubeAudioPlayerScreen({super.key, required this.video});

  @override
  State<YouTubeAudioPlayerScreen> createState() => _YouTubeAudioPlayerScreenState();
}

class _YouTubeAudioPlayerScreenState extends State<YouTubeAudioPlayerScreen> {
  bool _isLoading = true;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final url = await YouTubeAudioService.instance.getAudioStreamUrl(widget.video.id);
      if (url != null && mounted) {
        setState(() {
          _audioUrl = url;
          _isLoading = false;
        });
        
        final handler = globalAudioHandler as QuranAudioHandler;
        await handler.playUrl(
          url,
          title: widget.video.title,
          artist: widget.video.author,
          artUri: widget.video.thumbnailUrl,
          album: "Islamic Videos",
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Origin': 'https://co.wuk.sh',
            'Referer': 'https://co.wuk.sh/',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-site',
            'Connection': 'keep-alive',
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load audio stream')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error initializing audio: $e');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Blur Image
          CachedNetworkImage(
            imageUrl: widget.video.thumbnailUrl,
            fit: BoxFit.cover,
            httpHeaders: const {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ),
          // Blur & Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.black : Colors.white).withOpacity(0.7),
                  (isDark ? Colors.black : Colors.white).withOpacity(0.9),
                  (isDark ? AppColors.backgroundDark : AppColors.background),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: BackdropFilter(
              filter: ColorFilter.mode(
                (isDark ? Colors.black : Colors.white).withOpacity(0.4),
                BlendMode.srcOver,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildArtwork(),
                        _buildMetadata(isDark),
                        Column(
                          children: [
                            _buildProgressBar(isDark),
                            const SizedBox(height: 32),
                            _buildControls(isDark),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, 
                color: isDark ? Colors.white : AppColors.textPrimary, size: 36),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: CachedNetworkImage(
          imageUrl: widget.video.thumbnailUrl,
          fit: BoxFit.cover,
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(color: Colors.white),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.music_note, size: 80, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(bool isDark) {
    return Column(
      children: [
        Text(
          widget.video.title,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.video.author,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        
        return StreamBuilder<MediaItem?>(
          stream: globalAudioHandler.mediaItem,
          builder: (context, mediaSnapshot) {
            final duration = mediaSnapshot.data?.duration ?? Duration.zero;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                    onChanged: (value) {
                      globalAudioHandler.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), 
                        style: AppTextStyles.labelMedium.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
                      Text(_formatDuration(duration), 
                        style: AppTextStyles.labelMedium.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildControls(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10_rounded, size: 36),
          color: isDark ? Colors.white70 : Colors.black54,
          onPressed: () {
            globalAudioHandler.rewind();
            HapticFeedback.lightImpact();
          },
        ),
        StreamBuilder<PlaybackState>(
          stream: globalAudioHandler.playbackState,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;

            if (processingState == AudioProcessingState.loading || processingState == AudioProcessingState.buffering || _isLoading) {
              return Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              );
            } else if (playing != true) {
              return _buildPlayButton(Icons.play_arrow_rounded, () => globalAudioHandler.play());
            } else if (processingState != AudioProcessingState.completed) {
              return _buildPlayButton(Icons.pause_rounded, () => globalAudioHandler.pause());
            } else {
              return _buildPlayButton(Icons.replay_rounded, () => globalAudioHandler.seek(Duration.zero));
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10_rounded, size: 36),
          color: isDark ? Colors.white70 : Colors.black54,
          onPressed: () {
            globalAudioHandler.fastForward();
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }

  Widget _buildPlayButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 52, color: Colors.white),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
