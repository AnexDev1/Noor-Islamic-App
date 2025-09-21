import 'package:flutter/material.dart';
import '../../domain/surah_info.dart';
import '../surah_detail_screen.dart';
import '../../audio/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ModernSurahList extends StatelessWidget {
  final List<SurahInfo> surahs;
  final SimpleQuranAudioPlayer audioService;

  const ModernSurahList({
    super.key,
    required this.surahs,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        final surahNumber = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: InkWell(
            onTap: () {
              // Stop current audio before navigating
              audioService.stop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SurahDetailScreen(
                    surahNo: surahNumber,
                    surahName: surah.surahName,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Surah Number Circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        surahNumber.toString(),
                        style: AppTextStyles.heading4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Surah Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // English and Arabic Names
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                surah.surahName,
                                style: AppTextStyles.heading4,
                              ),
                            ),
                            Text(
                              surah.surahNameArabic,
                              style: AppTextStyles.arabicMedium.copyWith(
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Translation and Details
                        Text(
                          surah.surahNameTranslation,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Stats Row
                        Row(
                          children: [
                            _buildStatChip(
                              icon: Icons.place,
                              label: surah.revelationPlace,
                              color: surah.revelationPlace == 'Makkah'
                                  ? AppColors.accent
                                  : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.format_list_numbered,
                              label: '${surah.totalAyah} verses',
                              color: AppColors.textTertiary,
                            ),
                          ],
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
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
