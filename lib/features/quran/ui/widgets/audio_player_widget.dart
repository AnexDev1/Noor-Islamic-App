import 'package:flutter/material.dart';
import '../../audio/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AudioPlayerWidget extends StatefulWidget {
  final SimpleQuranAudioPlayer audioService;

  const AudioPlayerWidget({
    super.key,
    required this.audioService,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Listen to audio service changes
    widget.audioService.isPlaying.addListener(_updatePlayerVisibility);
    widget.audioService.currentSurahName.addListener(_updatePlayerVisibility);
  }

  @override
  void dispose() {
    widget.audioService.isPlaying.removeListener(_updatePlayerVisibility);
    widget.audioService.currentSurahName.removeListener(_updatePlayerVisibility);
    _slideController.dispose();
    super.dispose();
  }

  void _updatePlayerVisibility() {
    if (widget.audioService.currentSurahName.value.isNotEmpty) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.audioService.currentSurahName,
      builder: (context, surahName, child) {
        if (surahName.isEmpty) return const SizedBox.shrink();

        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Row - Title and Close
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Now Playing: $surahName',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.audioService.stop();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress Bar
                ValueListenableBuilder<Duration>(
                  valueListenable: widget.audioService.position,
                  builder: (context, position, child) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: widget.audioService.duration,
                      builder: (context, duration, child) {
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withAlpha(77),
                                thumbColor: Colors.white,
                                overlayColor: Colors.white.withAlpha(51),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  final seekTo = Duration(
                                    milliseconds: (duration.inMilliseconds * value).round(),
                                  );
                                  widget.audioService.seek(seekTo);
                                },
                              ),
                            ),

                            // Time Labels
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withAlpha(204),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withAlpha(204),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    IconButton(
                      onPressed: () {
                        widget.audioService.seekBackward();
                      },
                      icon: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Play/Pause Button
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.audioService.isPlaying,
                      builder: (context, isPlaying, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: IconButton(
                            onPressed: () {
                              if (isPlaying) {
                                widget.audioService.pause();
                              } else {
                                widget.audioService.resume();
                              }
                            },
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    // Forward Button
                    IconButton(
                      onPressed: () {
                        widget.audioService.seekForward();
                      },
                      icon: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
