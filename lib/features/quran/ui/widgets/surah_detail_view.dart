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
  final bool showTranslation;

  const SurahDetailView({
    super.key,
    required this.surahDetail,
    required this.translations,
    required this.reciterId,
    required this.audioService,
    required this.reciterName,
    this.showTranslation = true,
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
    final apiUrl =
        'https://api.quran.com/api/v4/chapter_recitations/$reciterId?chapter_number=$surahNo';

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
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
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

          // Play Full Surah Button
          _buildPlayButton(),

          const SizedBox(height: 32),

          // Verses Section
          _buildVersesSection(),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return ValueListenableBuilder<String>(
      valueListenable: widget.audioService.currentSurahName,
      builder: (context, currentSurah, child) {
        final isCurrentSurah = currentSurah == widget.surahDetail.surahName;

        return ValueListenableBuilder<bool>(
          valueListenable: widget.audioService.isPlaying,
          builder: (context, isPlaying, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrentSurah
                      ? [AppColors.accent, AppColors.accent.withOpacity(0.8)]
                      : [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isCurrentSurah ? AppColors.accent : AppColors.primary)
                            .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isCurrentSurah && isPlaying) {
                      widget.audioService.pause();
                    } else if (isCurrentSurah && !isPlaying) {
                      widget.audioService.resume();
                    } else {
                      _playAudio();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCurrentSurah && isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCurrentSurah && isPlaying
                            ? 'Pause Recitation'
                            : isCurrentSurah
                            ? 'Resume Recitation'
                            : 'Play Full Surah',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVersesSection() {
    // Arabic Only Mode
    if (!widget.showTranslation) {
      return _buildArabicOnlyVerses();
    }

    // With Translation Mode
    return _buildVersesWithTranslation();
  }

  Widget _buildArabicOnlyVerses() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bismillah (except for Surah At-Tawbah)
          if (widget.surahDetail.surahNo != 9) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: AppTextStyles.arabicLarge.copyWith(
                    fontSize: 26,
                    color: AppColors.primary,
                    height: 2.0,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Arabic Verses in a flowing text format
          SelectableText.rich(
            TextSpan(
              children: widget.surahDetail.arabic1.asMap().entries.map((entry) {
                final index = entry.key;
                final arabicText = entry.value;
                return TextSpan(
                  children: [
                    TextSpan(
                      text: arabicText,
                      style: AppTextStyles.arabicLarge.copyWith(
                        fontSize: 26,
                        height: 2.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' ﴿${_toArabicNumber(index + 1)}﴾ ',
                      style: AppTextStyles.arabicLarge.copyWith(
                        fontSize: 20,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  Widget _buildVersesWithTranslation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text('Verses with Translation', style: AppTextStyles.heading3),
          ],
        ),

        const SizedBox(height: 16),

        ...widget.translations.asMap().entries.map((entry) {
          final index = entry.key;
          final translation = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse Number Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Verse ${index + 1}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Arabic Text
                      if (translation.arabicText != null &&
                          translation.arabicText!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            translation.arabicText!,
                            style: AppTextStyles.arabicLarge.copyWith(
                              fontSize: 24,
                              height: 2.0,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Translation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          translation.translation,
                          style: AppTextStyles.bodyLarge.copyWith(
                            height: 1.7,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Bottom spacing
        const SizedBox(height: 40),
      ],
    );
  }
}
