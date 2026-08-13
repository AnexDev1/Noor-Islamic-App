import 'package:flutter/material.dart';
import '../../domain/surah_info.dart';
import '../surah_detail_screen.dart';
import '../../audio/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SurahList extends StatelessWidget {
  final List<SurahInfo> surahs;
  final SimpleQuranAudioPlayer audioService;

  const SurahList({
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
        final surahNumber = surah.surahNumber;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE6E3)),
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
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  // Surah Number Circle
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.quranCard.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        surahNumber.toString(),
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.quranCard,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

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
                                color: AppColors.quranCard,
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

                        const SizedBox(height: 7),

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
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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
