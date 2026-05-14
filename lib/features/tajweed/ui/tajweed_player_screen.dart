import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../quran/domain/surah_detail.dart';
import '../../quran/domain/surah_info.dart';
import '../providers/tajweed_provider.dart';
import '../services/tajweed_audio_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../quran/data/surah_api.dart';

class TajweedPlayerScreen extends ConsumerStatefulWidget {
  final SurahDetail surahDetail;
  final int startAyah;
  final int endAyah;

  const TajweedPlayerScreen({
    super.key,
    required this.surahDetail,
    required this.startAyah,
    required this.endAyah,
  });

  @override
  ConsumerState<TajweedPlayerScreen> createState() =>
      _TajweedPlayerScreenState();
}

class _TajweedPlayerScreenState extends ConsumerState<TajweedPlayerScreen> {
  bool _isImageMode = false;
  final ScrollController _scrollController = ScrollController();
  int _lastAutoScrolledAyah = -1;
  late SurahDetail _currentSurahDetail;
  bool _isLoadingSurah = false;

  @override
  void initState() {
    super.initState();
    _currentSurahDetail = widget.surahDetail;
    // Pre-cache first image
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
      TajweedAudioService.instance.currentAyahNumber.addListener(
        _onAyahChanged,
      );
    });
  }

  @override
  void dispose() {
    TajweedAudioService.instance.currentAyahNumber.removeListener(
      _onAyahChanged,
    );
    TajweedAudioService.instance.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSession() {
    final state = ref.read(tajweedProvider);
    final notifier = ref.read(tajweedProvider.notifier);

    // If already playing the EXACT same range/reciter, we could skip loading,
    // but typically we reload to ensure proper sequence.
    TajweedAudioService.instance.loadAyahRange(
      surahNo: _currentSurahDetail.surahNo,
      surahName: _currentSurahDetail.surahName,
      startAyah: widget
          .startAyah, // Will only be respected on first load or needs adjustment
      endAyah: _currentSurahDetail.totalAyah,
      folderName: notifier.currentReciter.folderName,
      repeatCount: state.repeatCount,
      loopEntireRange: state.loopRange,
    );
  }

  void _startSessionForSurah(SurahDetail surah) {
    final state = ref.read(tajweedProvider);
    final notifier = ref.read(tajweedProvider.notifier);

    TajweedAudioService.instance.stop();

    TajweedAudioService.instance.loadAyahRange(
      surahNo: surah.surahNo,
      surahName: surah.surahName,
      startAyah: 1, // Full surah when skipping
      endAyah: surah.totalAyah,
      folderName: notifier.currentReciter.folderName,
      repeatCount: state.repeatCount,
      loopEntireRange: state.loopRange,
    );
  }

  Future<void> _skipToNextSurah() async {
    if (_currentSurahDetail.surahNo >= 114) return;
    setState(() => _isLoadingSurah = true);
    try {
      final nextSurahDetail = await SurahApi.fetchSurahDetail(
        _currentSurahDetail.surahNo + 1,
      );
      setState(() {
        _currentSurahDetail = nextSurahDetail;
        _isLoadingSurah = false;
        _lastAutoScrolledAyah = -1;
      });
      _startSessionForSurah(_currentSurahDetail);
    } catch (e) {
      setState(() => _isLoadingSurah = false);
    }
  }

  Future<void> _skipToPreviousSurah() async {
    if (_currentSurahDetail.surahNo <= 1) return;
    setState(() => _isLoadingSurah = true);
    try {
      final prevSurahDetail = await SurahApi.fetchSurahDetail(
        _currentSurahDetail.surahNo - 1,
      );
      setState(() {
        _currentSurahDetail = prevSurahDetail;
        _isLoadingSurah = false;
        _lastAutoScrolledAyah = -1;
      });
      _startSessionForSurah(_currentSurahDetail);
    } catch (e) {
      setState(() => _isLoadingSurah = false);
    }
  }

  void _onAyahChanged() {
    if (!mounted) return;
    final currentAyah = TajweedAudioService.instance.currentAyahNumber.value;
    if (currentAyah == -1) return;

    // Auto-scroll in text mode
    if (!_isImageMode && currentAyah != _lastAutoScrolledAyah) {
      _lastAutoScrolledAyah = currentAyah;

      // Proportional scrolling by character count for extremely accurate flowing text tracking
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        int totalChars = 0;
        int charsBeforeCurrent = 0;

        for (int i = 0; i < _currentSurahDetail.totalAyah; i++) {
          final ayahLength = _currentSurahDetail.arabic1.length > i
              ? _currentSurahDetail.arabic1[i].length
              : 0;
          totalChars += ayahLength;
          if (i < currentAyah - 1) {
            charsBeforeCurrent += ayahLength;
          }
        }

        if (totalChars > 0) {
          // Add a small buffer to position it slightly below the top edge
          final targetOffset = (charsBeforeCurrent / totalChars) * maxScroll;
          _scrollController.animateTo(
            targetOffset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  String _getAyahImageUrl(int surah, int ayah) {
    return 'https://everyayah.com/data/quranpngs/${surah}_$ayah.png';
  }

  @override
  Widget build(BuildContext context) {
    final tajweedNotifier = ref.read(tajweedProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Column(
          children: [
            Text(_currentSurahDetail.surahName, style: AppTextStyles.heading3),
            Text(
              tajweedNotifier.currentReciter.name,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isImageMode ? Icons.text_fields : Icons.image,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _isImageMode = !_isImageMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingSurah
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : ValueListenableBuilder<int>(
                    valueListenable:
                        TajweedAudioService.instance.currentAyahNumber,
                    builder: (context, currentAyah, _) {
                      if (currentAyah == -1) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        );
                      }

                      if (_isImageMode) {
                        return _buildImageMode(currentAyah);
                      } else {
                        return _buildTextMode(currentAyah);
                      }
                    },
                  ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildImageMode(int currentAyah) {
    final imageUrl = _getAyahImageUrl(_currentSurahDetail.surahNo, currentAyah);

    // Pre-cache next ayah image
    if (currentAyah < _currentSurahDetail.totalAyah) {
      final nextImageUrl = _getAyahImageUrl(
        _currentSurahDetail.surahNo,
        currentAyah + 1,
      );
      precacheImage(CachedNetworkImageProvider(nextImageUrl), context);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) =>
              const CircularProgressIndicator(color: AppColors.accent),
          errorWidget: (context, url, error) {
            final l10n = AppLocalizations.of(context);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(l10n?.error ?? 'Error', style: AppTextStyles.labelMedium),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextMode(int currentAyah) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8E8), // Warm authentic paper color
          border: Border.all(color: AppColors.accent, width: 2.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accent.withOpacity(0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: _currentSurahDetail.arabic1.asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final ayahNumber = index + 1;
                final arabicText = entry.value;
                final isHighlighted = currentAyah == ayahNumber;

                return TextSpan(
                  children: [
                    TextSpan(
                      text: '${arabicText.trim()} ',
                      style: AppTextStyles.arabicLarge.copyWith(
                        fontSize:
                            26, // Reduced font size for better readability
                        height: 2.0,
                        color: isHighlighted
                            ? const Color(0xFFB8860B)
                            : const Color(0xFF1A1D23),
                        fontWeight: isHighlighted
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '﴿${_toArabicNumber(ayahNumber)}﴾ ',
                      style: AppTextStyles.arabicLarge.copyWith(
                        fontSize: 20,
                        color: isHighlighted
                            ? const Color(0xFFB8860B)
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            textAlign: TextAlign
                .justify, // Stretch words end-to-end like a physical Quran
            textDirection: TextDirection.rtl,
          ),
        ),
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

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowHeavy,
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Info & Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48), // Balance for speed button
              ValueListenableBuilder<int>(
                valueListenable: TajweedAudioService.instance.currentAyahNumber,
                builder: (context, currentAyah, _) {
                  final l10n = AppLocalizations.of(context);
                  if (currentAyah == -1) return const SizedBox.shrink();
                  return Text(
                    '${l10n?.ayah ?? "Ayah"} $currentAyah / ${_currentSurahDetail.totalAyah}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
              _buildSpeedControl(),
            ],
          ),
          const SizedBox(height: 8),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
                tooltip: 'Previous Surah',
                onPressed: _currentSurahDetail.surahNo > 1
                    ? _skipToPreviousSurah
                    : null,
              ),
              IconButton(
                icon: const Icon(
                  Icons.fast_rewind_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
                onPressed: TajweedAudioService.instance.seekToPrevious,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: TajweedAudioService.instance.isLoading,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: TajweedAudioService.instance.isPlaying,
                    builder: (context, isPlaying, _) {
                      return GestureDetector(
                        onTap: isPlaying
                            ? TajweedAudioService.instance.pause
                            : TajweedAudioService.instance.play,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: AppColors.accentGradient,
                            ),
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.textOnAccent,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.fast_forward_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
                onPressed: TajweedAudioService.instance.seekToNext,
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
                tooltip: 'Next Surah',
                onPressed: _currentSurahDetail.surahNo < 114
                    ? _skipToNextSurah
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    return PopupMenuButton<double>(
      icon: const Icon(
        Icons.speed_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      tooltip: 'Playback Speed',
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (double speed) {
        TajweedAudioService.instance.setSpeed(speed);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<double>>[
        const PopupMenuItem<double>(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem<double>(value: 0.75, child: Text('0.75x')),
        const PopupMenuItem<double>(value: 1.0, child: Text('1.0x (Normal)')),
        const PopupMenuItem<double>(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem<double>(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem<double>(value: 2.0, child: Text('2.0x')),
      ],
    );
  }
}
