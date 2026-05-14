import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../quran/ui/quran_screen.dart';
import '../../quran/ui/listen_quran_screen.dart';
import '../../tajweed/ui/hifz_mode_screen.dart';

class QuranHubScreen extends StatelessWidget {
  const QuranHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          l10n?.quran ?? 'Al Quran',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Elegant subtle top background decoration
          Positioned(
            top: -100,
            right: -80,
            child: Opacity(
              opacity: 0.03,
              child: Icon(
                Icons.menu_book_rounded,
                size: 300,
                color: AppColors.primary,
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n?.quranChapters ?? 'Holy Quran Chapters',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.customizeQuranExperience ??
                      'Customize your Quran reading experience',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Read & Reflect Card
                _buildProfessionalCard(
                  context: context,
                  title: l10n?.quran ?? 'Quran',
                  subtitle:
                      l10n?.showTranslationDesc ??
                      'Multi-language translations, beautiful Uthmani script, and tafsir.',
                  icon: Icons.menu_book_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuranScreen()),
                  ),
                ),
                const SizedBox(height: 20),

                // Listen & Stream Card
                _buildProfessionalCard(
                  context: context,
                  title: l10n?.listenQuran ?? 'Listen Quran',
                  subtitle:
                      l10n?.customizeQuranExperience ??
                      'Continuous playback of full surahs by world-renowned reciters.',
                  icon: Icons.headphones_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListenQuranScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tajweed & Hifz Card
                _buildProfessionalCard(
                  context: context,
                  title: 'Tajweed & Hifz',
                  subtitle:
                      l10n?.tipFocus ??
                      'Ayah-by-Ayah visual sync, audio repetition, and Mus\'haf view.',
                  icon: Icons.repeat_one_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HifzModeScreen()),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Typically pure white in light mode
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ), // Extremely delicate border
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(
              0.04,
            ), // Very soft, tinted shadow
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: AppColors.primary.withOpacity(0.03),
          splashColor: AppColors.primary.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                        AppColors.background, // Slightly off-white background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.05)),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 20),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle chevron
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary.withOpacity(0.4),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
