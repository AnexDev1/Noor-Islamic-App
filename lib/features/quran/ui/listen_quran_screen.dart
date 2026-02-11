import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../data/quran_api.dart';
import '../data/reciters_api.dart';
import '../data/audio_api.dart';
import '../domain/surah_info.dart';
import '../../../core/services/global_audio_handler.dart';
import '../audio/quran_audio_handler.dart';

class ListenQuranScreen extends ConsumerStatefulWidget {
  const ListenQuranScreen({super.key});

  @override
  ConsumerState<ListenQuranScreen> createState() => _ListenQuranScreenState();
}

class _ListenQuranScreenState extends ConsumerState<ListenQuranScreen> {
  late Future<List<SurahInfo>> _surahsFuture;
  late Future<Map<String, String>> _recitersFuture;

  String _selectedReciterId = 'ar.alafasy';
  String _selectedReciterName = 'Mishary Rashid Al-Afasy';

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _surahsFuture = QuranApi.fetchSurahs();
    _recitersFuture = RecitersApi.fetchReciters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurahInfo> _filterSurahs(List<SurahInfo> surahs) {
    if (_searchQuery.isEmpty) return surahs;

    return surahs.where((surah) {
      return surah.surahName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          surah.surahNameArabic.contains(_searchQuery) ||
          surah.surahNameTranslation.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  void _showReciterSelector(Map<String, String> reciters) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations.of(context)!.reciter,
                    style: AppTextStyles.heading2,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: reciters.length,
                    itemBuilder: (context, index) {
                      final id = reciters.keys.elementAt(index);
                      final name = reciters.values.elementAt(index);
                      final isSelected = id == _selectedReciterId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  name.substring(0, 1),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                        ),
                        title: Text(
                          name,
                          style: isSelected
                              ? AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                )
                              : AppTextStyles.bodyMedium,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedReciterId = id;
                            _selectedReciterName = name;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _playSurah(
    SurahInfo surah,
    int surahNumber,
    List<SurahInfo> allSurahs,
  ) async {
    try {
      if (globalAudioHandler is QuranAudioHandler) {
        final handler = globalAudioHandler as QuranAudioHandler;
        handler.setContext(allSurahs, _selectedReciterId, _selectedReciterName);
        // surahNumber is 1-based, index is 0-based
        await handler.playSurahAtIndex(surahNumber - 1);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildReciterSelector(l10n),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: _buildSearchBar(l10n),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder<List<SurahInfo>>(
                    future: _surahsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerList();
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.error, style: AppTextStyles.heading3),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  snapshot.error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _surahsFuture = QuranApi.fetchSurahs();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(l10n.noSurahsFound));
                      }

                      final surahs = _filterSurahs(snapshot.data!);

                      return ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 150,
                        ), // Space for player
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          final fullList = snapshot.data!;
                          final realIndex = fullList.indexOf(surah);
                          return _buildSurahTile(
                            surah,
                            realIndex + 1,
                            fullList,
                          );
                        },
                      );
                    },
                  ),
                  _buildBottomPlayer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Listen Quran', // TODO: Localize
                style: AppTextStyles.heading2,
              ),
              Text(
                'Stream, download & listen',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: l10n.searchSurah,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Widget _buildReciterSelector(AppLocalizations l10n) {
    return FutureBuilder<Map<String, String>>(
      future: _recitersFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return InkWell(
          onTap: () => _showReciterSelector(snapshot.data!),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reciter,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _selectedReciterName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahTile(
    SurahInfo surah,
    int number,
    List<SurahInfo> allSurahs,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Text(
            number.toString(),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          surah.surahName,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${surah.totalAyah} Verses • ${surah.surahNameTranslation}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: StreamBuilder<MediaItem?>(
          stream: globalAudioHandler.mediaItem,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data?.title == surah.surahName;

            return IconButton(
              onPressed: () => _playSurah(surah, number, allSurahs),
              icon: Icon(
                isPlaying
                    ? Icons.graphic_eq
                    : Icons.play_circle_outline_rounded,
                color: isPlaying ? AppColors.accent : AppColors.primary,
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: StreamBuilder<MediaItem?>(
        stream: globalAudioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.music_note, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              mediaItem.artist ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(),
                  const SizedBox(height: 12),
                  _buildPlayerControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<AudioState>(
      stream: _audioStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final position = state?.position ?? Duration.zero;
        final duration = state?.duration ?? Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                min: 0,
                max: duration.inMilliseconds.toDouble(),
                value: position.inMilliseconds.toDouble().clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                ),
                onChanged: (value) {
                  globalAudioHandler.seek(
                    Duration(milliseconds: value.toInt()),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerControls() {
    return StreamBuilder<PlaybackState>(
      stream: globalAudioHandler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        final speed = snapshot.data?.speed ?? 1.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                double newSpeed = speed == 1.0
                    ? 1.5
                    : (speed == 1.5 ? 2.0 : (speed == 2.0 ? 0.5 : 1.0));
                (globalAudioHandler as QuranAudioHandler).setSpeed(newSpeed);
              },
              icon: Text(
                "${speed}x",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => globalAudioHandler.rewind(),
              icon: Icon(
                Icons.replay_10_rounded,
                size: 28,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => playing
                    ? globalAudioHandler.pause()
                    : globalAudioHandler.play(),
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              onPressed: () => globalAudioHandler.fastForward(),
              icon: Icon(
                Icons.forward_10_rounded,
                size: 28,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () => globalAudioHandler.stop(),
              icon: Icon(
                Icons.stop_circle_outlined,
                size: 28,
                color: AppColors.error,
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<AudioState> get _audioStateStream {
    return Stream.periodic(const Duration(milliseconds: 200), (_) {
      final state = globalAudioHandler.playbackState.value;
      final item = globalAudioHandler.mediaItem.value;
      return AudioState(item?.duration ?? Duration.zero, state.position);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class AudioState {
  final Duration duration;
  final Duration position;
  AudioState(this.duration, this.position);
}
