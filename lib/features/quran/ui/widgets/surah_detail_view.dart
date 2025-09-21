import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/surah_detail.dart';
import '../../domain/quran_enc_translation.dart';
import '../../audio/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SurahDetailView extends StatefulWidget {
  final SurahDetail surahDetail;
  final List<QuranEncTranslation> translations;
  final String reciterId;
  final SimpleQuranAudioPlayer audioService;
  final String reciterName;

  const SurahDetailView({
    super.key,
    required this.surahDetail,
    required this.translations,
    required this.reciterId,
    required this.audioService,
    required this.reciterName,
  });

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  String? _audioUrl;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _fetchAudioUrl();
  }

  @override
  void didUpdateWidget(covariant SurahDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reciterId != widget.reciterId ||
        oldWidget.surahDetail.surahNo != widget.surahDetail.surahNo) {
      _fetchAudioUrl();
    }
  }

  Future<void> _fetchAudioUrl() async {
    setState(() {
      _isLoadingAudio = true;
    });

    final reciterId = widget.reciterId;
    final surahNo = widget.surahDetail.surahNo;
    final apiUrl = 'https://api.quran.com/api/v4/chapter_recitations/$reciterId?chapter_number=$surahNo';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioFiles = data['audio_files'] as List<dynamic>;
        if (audioFiles.isNotEmpty) {
          setState(() {
            _audioUrl = audioFiles[0]['audio_url'] as String?;
            _isLoadingAudio = false;
          });
        } else {
          setState(() {
            _audioUrl = null;
            _isLoadingAudio = false;
          });
        }
      } else {
        setState(() {
          _audioUrl = null;
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      setState(() {
        _audioUrl = null;
        _isLoadingAudio = false;
      });
    }
  }

  Widget _buildSurahHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Arabic Name
          Text(
            widget.surahDetail.surahNameArabic,
            style: AppTextStyles.arabicLarge.copyWith(
              fontSize: 32,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),

          const SizedBox(height: 12),

          // English Name and Translation
          Text(
            widget.surahDetail.surahName,
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            widget.surahDetail.surahNameTranslation,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge(
                icon: Icons.place,
                label: widget.surahDetail.revelationPlace,
                color: widget.surahDetail.revelationPlace == 'Makkah'
                    ? AppColors.accent
                    : AppColors.secondary,
              ),
              const SizedBox(width: 16),
              _buildStatBadge(
                icon: Icons.format_list_numbered,
                label: '${widget.surahDetail.totalAyah} verses',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reciter: ${widget.reciterName}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ValueListenableBuilder<String>(
                      valueListenable: widget.audioService.currentSurahName,
                      builder: (context, surahName, _) {
                        return Text(
                          surahName.isNotEmpty ? surahName : 'Not Playing',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildPlayPauseButton(),
            ],
          ),
          const SizedBox(height: 16),
          _buildAudioProgressBar(),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return ValueListenableBuilder<String>(
      valueListenable: widget.audioService.currentSurahName,
      builder: (context, currentSurah, child) {
        final isCurrentSurah = currentSurah == widget.surahDetail.surahName;

        return ValueListenableBuilder<bool>(
          valueListenable: widget.audioService.isPlaying,
          builder: (context, isPlaying, child) {
            return ElevatedButton.icon(
              onPressed: () {
                if (isCurrentSurah && isPlaying) {
                  widget.audioService.pause();
                } else if (isCurrentSurah && !isPlaying) {
                  widget.audioService.resume();
                } else {
                  _playAudio();
                }
              },
              icon: Icon(
                isCurrentSurah && isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 24,
              ),
              label: Text(
                isCurrentSurah && isPlaying
                    ? 'Pause Recitation'
                    : isCurrentSurah
                        ? 'Resume Recitation'
                        : 'Play Recitation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentSurah
                    ? AppColors.accent
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAudioProgressBar() {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.audioService.position,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.audioService.duration,
          builder: (context, duration, _) {
            return Column(
              children: [
                Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0.0,
                  max: duration.inSeconds.toDouble().isNaN ? 0.0 : duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    widget.audioService.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withOpacity(0.3),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        _formatDuration(duration),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (hours > 0) hours.toString(),
      minutes,
      seconds,
    ].join(':');
  }

  Future<void> _playAudio() async {
    if (_audioUrl != null) {
      await widget.audioService.play(
        _audioUrl!,
        widget.surahDetail.surahName,
        reciterName: widget.reciterName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surah Header
          _buildSurahHeader(),

          const SizedBox(height: 24),

          // Audio Player Section
          _buildAudioSection(),

          const SizedBox(height: 32),

          // Verses Section
          _buildVersesSection(),
        ],
      ),
    );
  }

  Widget _buildVersesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verses with Translation',
          style: AppTextStyles.heading2,
        ),

        const SizedBox(height: 16),

        ...widget.translations.asMap().entries.map((entry) {
          final index = entry.key;
          final translation = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse Number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verse ${index + 1}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Arabic Text
                if (translation.arabicText != null && translation.arabicText!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      translation.arabicText!,
                      style: AppTextStyles.arabicLarge.copyWith(
                        fontSize: 22,
                        height: 2.0,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),

                const SizedBox(height: 12),

                // Translation
                Text(
                  translation.translation,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        }),

        // Bottom spacing
        const SizedBox(height: 100),
      ],
    );
  }
}
