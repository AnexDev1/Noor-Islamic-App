import 'package:flutter/material.dart';
import '../data/amharic_translation_api.dart';
import '../data/surah_api.dart';
import '../data/reciters_api.dart';
import '../domain/amharic_translation.dart';
import '../domain/quran_enc_translation.dart';
import '../domain/surah_detail.dart';
import '../audio/audio_player_service.dart';
import 'widgets/surah_detail_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNo;
  final String surahName;
  const SurahDetailScreen({super.key, required this.surahNo, required this.surahName});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> with TickerProviderStateMixin {
  late Future<SurahDetail> _surahDetailFuture;
  late Future<List<QuranEncTranslation>> _translationFuture;
  late Future<Map<String, String>> _recitersFuture;
  final SimpleQuranAudioPlayer _audioService = SimpleQuranAudioPlayer.instance;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedTranslationKey = 'amharic_zain';
  String _selectedReciterId = '1';
  Map<String, String> _reciters = {};

  final Map<String, String> _translationOptions = {
    'amharic_zain': 'Amharic',
    'oromo_ababor': 'Oromo',
    'english_rwwad': 'English',
  };

  @override
  void initState() {
    super.initState();
    _surahDetailFuture = SurahApi.fetchSurahDetail(widget.surahNo);
    _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(_selectedTranslationKey, widget.surahNo);
    _recitersFuture = RecitersApi.fetchReciters();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();

    _recitersFuture.then((reciters) {
      setState(() {
        _reciters = reciters;
        if (_reciters.isNotEmpty && !_reciters.containsKey(_selectedReciterId)) {
          _selectedReciterId = _reciters.keys.first;
        }
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
        _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(_selectedTranslationKey, widget.surahNo);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            _buildModernAppBar(),

            // Settings Panel
            SliverToBoxAdapter(
              child: _buildSettingsPanel(),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: FutureBuilder<SurahDetail>(
                future: _surahDetailFuture,
                builder: (context, surahSnapshot) {
                  if (surahSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (surahSnapshot.hasError) {
                    return _buildErrorWidget('Error loading surah: ${surahSnapshot.error}');
                  } else if (!surahSnapshot.hasData) {
                    return _buildErrorWidget('No surah data found');
                  }

                  return FutureBuilder<List<QuranEncTranslation>>(
                    future: _translationFuture,
                    builder: (context, translationSnapshot) {
                      if (translationSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (translationSnapshot.hasError) {
                        return _buildErrorWidget('Error loading translation: ${translationSnapshot.error}');
                      } else if (!translationSnapshot.hasData) {
                        return _buildErrorWidget('No translation found');
                      }

                      return SurahDetailView(
                        surahDetail: surahSnapshot.data!,
                        translations: translationSnapshot.data!,
                        reciterId: _selectedReciterId,
                        audioService: _audioService,
                        reciterName: _reciters[_selectedReciterId] ?? 'Unknown Reciter',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
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
                            Text(
                              'Chapter ${widget.surahNo}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
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

  Widget _buildSettingsPanel() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),

          // Translation Selector
          _buildSelector(
            label: 'Translation Language',
            value: _selectedTranslationKey,
            options: _translationOptions,
            onChanged: _onTranslationChanged,
            icon: Icons.translate,
          ),

          const SizedBox(height: 16),

          // Reciter Selector
          FutureBuilder<Map<String, String>>(
            future: _recitersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildSelector(
                label: 'Reciter',
                value: _selectedReciterId,
                options: snapshot.data!,
                onChanged: _onReciterChanged,
                icon: Icons.record_voice_over,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String value,
    required Map<String, String> options,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: options.entries.map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Text(
                  e.value,
                  style: AppTextStyles.bodyMedium,
                ),
              )).toList(),
              onChanged: onChanged,
              isExpanded: true,
            ),
          ),
        ),
      ],
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
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.error,
              ),
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
                  _surahDetailFuture = SurahApi.fetchSurahDetail(widget.surahNo);
                  _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(_selectedTranslationKey, widget.surahNo);
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
