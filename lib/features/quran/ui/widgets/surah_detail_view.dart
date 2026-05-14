import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/audio_api.dart';
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
  final AudioPlayer _ayahAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _ayahPlayerSubscription;
  Map<int, String> _ayahAudioUrls = {};
  int? _playingAyahIndex;
  bool _isPlayingAyah = false;
  bool _isLoadingAyahAudio = false;

  @override
  void initState() {
    super.initState();
    _ayahPlayerSubscription = _ayahAudioPlayer.playerStateStream.listen((
      state,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlayingAyah = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _playingAyahIndex = null;
          _isPlayingAyah = false;
        }
      });
    });
    _fetchAudioUrl();
    _fetchAllAyahAudio();
  }

  @override
  void didUpdateWidget(covariant SurahDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reciterId != widget.reciterId ||
        oldWidget.surahDetail.surahNo != widget.surahDetail.surahNo) {
      _fetchAudioUrl();
      unawaited(_ayahAudioPlayer.stop());
      if (mounted) {
        setState(() {
          _playingAyahIndex = null;
          _isPlayingAyah = false;
        });
      }
      _fetchAllAyahAudio();
    }
  }

  @override
  void dispose() {
    _ayahPlayerSubscription?.cancel();
    _ayahAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchAudioUrl() async {
    // 1. Check if audio URL is available in the cached SurahDetail
    // This provides instant access without network calls
    if (widget.surahDetail.audio.containsKey(widget.reciterId)) {
      final dynamic audioEntry = widget.surahDetail.audio[widget.reciterId];
      // It can be a Map (most likely) or maybe just string if schema changed,
      // but based on 1.json it is a Map with "url" key.
      if (audioEntry is Map && audioEntry['url'] != null) {
        setState(() {
          _audioUrl = audioEntry['url'].toString();
        });
        return;
      }
    }

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
          });
        } else {
          setState(() {
            _audioUrl = null;
          });
        }
      } else {
        setState(() {
          _audioUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _audioUrl = null;
      });
    }
  }

  Future<void> _fetchAllAyahAudio() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingAyahAudio = true;
    });

    final ayahAudioUrls = <int, String>{};

    for (int i = 0; i < widget.surahDetail.totalAyah; i++) {
      final ayahNo = i + 1;
      try {
        final audioMap = await AudioApi.fetchAyahAudio(
          widget.surahDetail.surahNo,
          ayahNo,
        );
        final dynamic reciterAudio = audioMap[widget.reciterId];
        if (reciterAudio is Map && reciterAudio['url'] != null) {
          ayahAudioUrls[i] = reciterAudio['url'].toString();
        } else {
          ayahAudioUrls[i] = '';
        }
      } catch (_) {
        ayahAudioUrls[i] = '';
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _ayahAudioUrls = ayahAudioUrls;
      _isLoadingAyahAudio = false;
    });
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
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
      await _ayahAudioPlayer.stop();
      await widget.audioService.play(
        _audioUrl!,
        widget.surahDetail.surahName,
        reciterName: widget.reciterName,
      );
    }
  }

  Future<void> _toggleAyahAudio(int index) async {
    final url = _ayahAudioUrls[index];
    if (url == null || url.isEmpty) {
      return;
    }

    if (_playingAyahIndex == index && _isPlayingAyah) {
      await _ayahAudioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlayingAyah = false;
        });
      }
      return;
    }

    if (_playingAyahIndex == index && !_isPlayingAyah) {
      await _ayahAudioPlayer.play();
      if (mounted) {
        setState(() {
          _isPlayingAyah = true;
        });
      }
      return;
    }

    await widget.audioService.stop();
    await _ayahAudioPlayer.stop();
    await _ayahAudioPlayer.setUrl(url);
    await _ayahAudioPlayer.play();

    if (!mounted) {
      return;
    }

    setState(() {
      _playingAyahIndex = index;
      _isPlayingAyah = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 20),
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
                      ? [
                          AppColors.accent,
                          AppColors.accent.withValues(alpha: 0.8),
                        ]
                      : [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isCurrentSurah ? AppColors.accent : AppColors.primary)
                            .withValues(alpha: 0.3),
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
    return _buildAyahCards(showTranslation: widget.showTranslation);
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  Widget _buildAyahCards({required bool showTranslation}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              showTranslation ? 'Verses with Translation' : 'Verses',
              style: AppTextStyles.heading3,
            ),
          ],
        ),

        const SizedBox(height: 16),

        ...List.generate(widget.surahDetail.totalAyah, (index) {
          final translation = index < widget.translations.length
              ? widget.translations[index]
              : null;
          final arabicText = translation?.arabicText?.isNotEmpty == true
              ? translation!.arabicText!
              : (index < widget.surahDetail.arabic1.length
                    ? widget.surahDetail.arabic1[index]
                    : '');
          final audioUrl = _ayahAudioUrls[index] ?? '';

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
                    color: AppColors.primary.withValues(alpha: 0.05),
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
                        'Verse ${_toArabicNumber(index + 1)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (audioUrl.isNotEmpty)
                        IconButton(
                          onPressed: () => _toggleAyahAudio(index),
                          icon: Icon(
                            _playingAyahIndex == index && _isPlayingAyah
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          tooltip: _playingAyahIndex == index && _isPlayingAyah
                              ? 'Pause Ayah'
                              : 'Play Ayah',
                        ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (arabicText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            arabicText,
                            style: AppTextStyles.arabicLarge.copyWith(
                              fontSize: 24,
                              height: 2.0,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),

                      if (showTranslation &&
                          translation != null &&
                          translation.translation.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(
                              alpha: 0.5,
                            ),
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
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 40),
      ],
    );
  }
}
