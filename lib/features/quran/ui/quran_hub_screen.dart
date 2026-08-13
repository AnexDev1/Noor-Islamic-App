import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../tajweed/ui/hifz_mode_screen.dart';
import 'listen_quran_screen.dart';
import 'quran_screen.dart';

class QuranHubScreen extends StatelessWidget {
  const QuranHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            title: Text(l10n.quran, style: AppTextStyles.displaySmall),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            sliver: SliverList.list(
              children: [
                const _ManuscriptHeader(),
                const SizedBox(height: 24),
                _QuranPathCard(
                  eyebrow: 'READ',
                  title: l10n.quranChapters,
                  description: l10n.showTranslationDesc,
                  icon: Icons.auto_stories_rounded,
                  accent: AppColors.quranCard,
                  onTap: () => _open(context, const QuranScreen()),
                ),
                const SizedBox(height: 12),
                _QuranPathCard(
                  eyebrow: 'LISTEN',
                  title: l10n.listenQuran,
                  description: l10n.customizeQuranExperience,
                  icon: Icons.graphic_eq_rounded,
                  accent: AppColors.primaryLight,
                  onTap: () => _open(context, const ListenQuranScreen()),
                ),
                const SizedBox(height: 12),
                _QuranPathCard(
                  eyebrow: 'MEMORIZE',
                  title: 'Tajweed & Hifz',
                  description: l10n.tipFocus,
                  icon: Icons.repeat_one_rounded,
                  accent: AppColors.accent,
                  onTap: () => _open(context, const HifzModeScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _ManuscriptHeader extends StatelessWidget {
  const _ManuscriptHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          end: -14,
          top: -28,
          child: Icon(
            Icons.auto_stories_rounded,
            size: 150,
            color: Colors.white.withValues(alpha: .055),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'القرآن الكريم',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const Spacer(),
            Container(width: 38, height: 2, color: AppColors.accent),
            const SizedBox(height: 10),
            const Text(
              'Read slowly. Listen closely. Return often.',
              style: TextStyle(color: Color(0xFFD5DEEC), fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuranPathCard extends StatelessWidget {
  const _QuranPathCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFDCE6E3)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: AppTextStyles.overline.copyWith(color: accent),
                  ),
                  const SizedBox(height: 3),
                  Text(title, style: AppTextStyles.heading3),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
