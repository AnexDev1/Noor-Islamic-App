import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/learn_islam_provider.dart';

/// Curated Islamic video explorer with category filtering
/// and inline YouTube playback.
class VideoExplorerScreen extends ConsumerStatefulWidget {
  const VideoExplorerScreen({super.key});

  @override
  ConsumerState<VideoExplorerScreen> createState() =>
      _VideoExplorerScreenState();
}

class _VideoExplorerScreenState extends ConsumerState<VideoExplorerScreen> {
  String? _playingVideoId;
  YoutubePlayerController? _ytController;

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  void _playVideo(String videoId) {
    _ytController?.dispose();
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
    setState(() => _playingVideoId = videoId);
  }

  void _stopVideo() {
    _ytController?.pause();
    setState(() => _playingVideoId = null);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(videosCategoryProvider);

    // Get unique categories
    final categories = [
      'All',
      ...{for (final v in kCuratedVideos) v.category},
    ];

    // Filter videos
    final filteredVideos = selectedCategory == 'All'
        ? kCuratedVideos
        : kCuratedVideos.where((v) => v.category == selectedCategory).toList();

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories.elementAt(i);
              final isSelected = cat == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) =>
                      ref.read(videosCategoryProvider.notifier).state = cat,
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),

        // Inline player
        if (_playingVideoId != null && _ytController != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  YoutubePlayer(
                    controller: _ytController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.accent,
                    progressColors: const ProgressBarColors(
                      playedColor: AppColors.accent,
                      handleColor: AppColors.accent,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _stopVideo,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Video list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: filteredVideos.length,
            itemBuilder: (_, i) {
              final video = filteredVideos[i];
              final isPlaying = _playingVideoId == video.videoId;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: isPlaying
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () =>
                      isPlaying ? _stopVideo() : _playVideo(video.videoId),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                'https://img.youtube.com/vi/${video.videoId}/mqdefault.jpg',
                                width: 120,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 72,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(
                                    Icons.play_circle_fill,
                                    color: AppColors.textTertiary,
                                    size: 32,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(
                                      alpha: isPlaying ? 0.5 : 0.2,
                                    ),
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.channelName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  video.category,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
