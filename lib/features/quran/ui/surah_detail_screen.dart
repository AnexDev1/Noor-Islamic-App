import 'package:flutter/material.dart';
import '../data/amharic_translation_api.dart';
import '../data/surah_api.dart';
import '../data/reciters_api.dart';
import '../domain/amharic_translation.dart';
import '../domain/quran_enc_translation.dart';
import '../domain/surah_detail.dart';
import '../audio/audio_player_service.dart';
import 'widgets/surah_detail_view.dart';
import 'widgets/floating_audio_player.dart';
import 'widgets/quran_settings_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNo;
  final String surahName;
  const SurahDetailScreen({
    super.key,
    required this.surahNo,
    required this.surahName,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen>
    with TickerProviderStateMixin {
  late Future<SurahDetail> _surahDetailFuture;
  late Future<List<QuranEncTranslation>> _translationFuture;
  late Future<Map<String, String>> _recitersFuture;
  final SimpleQuranAudioPlayer _audioService = SimpleQuranAudioPlayer.instance;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedTranslationKey = 'amharic_zain';
  String _selectedReciterId = '1';
  Map<String, String> _reciters = {};
  String? _recitersError;
  bool _showTranslation = true;

  final Map<String, String> _translationOptions = {
    'amharic_zain': 'Amharic',
    'oromo_ababor': 'Oromo',
    'english_rwwad': 'English',
  };

  @override
  void initState() {
    super.initState();
    _surahDetailFuture = SurahApi.fetchSurahDetail(widget.surahNo);
    _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(
      _selectedTranslationKey,
      widget.surahNo,
    );
    _recitersFuture = RecitersApi.fetchReciters();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    _recitersFuture
        .then((reciters) {
          setState(() {
            _reciters = reciters;
            if (_reciters.isNotEmpty &&
                !_reciters.containsKey(_selectedReciterId)) {
              _selectedReciterId = _reciters.keys.first;
            }
          });
        })
        .catchError((e) {
          setState(() {
            _recitersError = AppHelpers.sanitizeError(e);
          });
        });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTranslationChanged(String? key) {
    if (key != null && key != _selectedTranslationKey) {
      setState(() {
        _selectedTranslationKey = key;
        _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(
          _selectedTranslationKey,
          widget.surahNo,
        );
      });
    }
  }

  void _onReciterChanged(String? id) {
    if (id != null && id != _selectedReciterId) {
      setState(() {
        _selectedReciterId = id;
        // Stop any currently playing audio
        _audioService.stop();
        // Rebuild the widget tree to pass the new reciter ID
      });
    }
  }

  void _onShowTranslationChanged(bool value) {
    setState(() {
      _showTranslation = value;
    });
  }

  void _openSettings() {
    if (_reciters.isEmpty && _recitersError != null) {
      AppHelpers.showSnackBar(context, _recitersError!);
    }

    QuranSettingsSheet.show(
      context: context,
      selectedTranslationKey: _selectedTranslationKey,
      selectedReciterId: _selectedReciterId,
      showTranslation: _showTranslation,
      translationOptions: _translationOptions,
      reciters: _reciters,
      onTranslationChanged: _onTranslationChanged,
      onReciterChanged: _onReciterChanged,
      onShowTranslationChanged: _onShowTranslationChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Modern App Bar with Settings Icon
                _buildModernAppBar(),

                // Main Content
                SliverToBoxAdapter(
                  child: FutureBuilder<SurahDetail>(
                    future: _surahDetailFuture,
                    builder: (context, surahSnapshot) {
                      if (surahSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (surahSnapshot.hasError) {
                        return _buildErrorWidget(
                          'Error loading surah: ${AppHelpers.sanitizeError(surahSnapshot.error)}',
                        );
                      } else if (!surahSnapshot.hasData) {
                        return _buildErrorWidget('No surah data found');
                      }

                      if (_showTranslation) {
                        return FutureBuilder<List<QuranEncTranslation>>(
                          future: _translationFuture,
                          builder: (context, translationSnapshot) {
                            if (translationSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else if (translationSnapshot.hasError) {
                              return _buildErrorWidget(
                                'Error loading translation: ${AppHelpers.sanitizeError(translationSnapshot.error)}',
                              );
                            } else if (!translationSnapshot.hasData) {
                              return _buildErrorWidget('No translation found');
                            }

                            return SurahDetailView(
                              surahDetail: surahSnapshot.data!,
                              translations: translationSnapshot.data!,
                              reciterId: _selectedReciterId,
                              audioService: _audioService,
                              reciterName:
                                  _reciters[_selectedReciterId] ??
                                  'Unknown Reciter',
                              showTranslation: _showTranslation,
                            );
                          },
                        );
                      } else {
                        // Arabic only mode - pass empty translations
                        return SurahDetailView(
                          surahDetail: surahSnapshot.data!,
                          translations: const [],
                          reciterId: _selectedReciterId,
                          audioService: _audioService,
                          reciterName:
                              _reciters[_selectedReciterId] ??
                              'Unknown Reciter',
                          showTranslation: _showTranslation,
                        );
                      }
                    },
                  ),
                ),

                // Bottom spacing for floating player
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Floating Audio Player at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingAudioPlayer(audioService: _audioService),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      actions: [
        // Settings Icon
        IconButton(
          onPressed: _openSettings,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.surahNo.toString(),
                          style: AppTextStyles.heading4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.surahName,
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Chapter ${widget.surahNo}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                if (!_showTranslation) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Arabic Only',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTextStyles.heading4.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _surahDetailFuture = SurahApi.fetchSurahDetail(
                    widget.surahNo,
                  );
                  _translationFuture =
                      QuranEncTranslationApi.fetchSurahTranslation(
                        _selectedTranslationKey,
                        widget.surahNo,
                      );
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
