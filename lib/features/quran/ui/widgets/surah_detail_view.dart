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
  final QuranAudioPlayerService audioService;
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.headphones,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Recitation',
                      style: AppTextStyles.heading4,
                    ),
                    Text(
                      'Reciter: ${widget.reciterName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Play Button
          if (_isLoadingAudio)
            const Center(child: CircularProgressIndicator())
          else if (_audioUrl == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Audio not available for this reciter',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ValueListenableBuilder<String>(
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
            ),
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
