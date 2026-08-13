import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/hadiths_api.dart';
import '../domain/chapter.dart';
import '../domain/hadith.dart';
import 'hadith_detail_screen.dart';

class ChapterDetailScreen extends StatefulWidget {
  const ChapterDetailScreen({
    super.key,
    required this.bookSlug,
    required this.chapter,
  });

  final String bookSlug;
  final HadithChapter chapter;

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  late Future<List<Hadith>> _hadithsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _hadithsFuture = HadithsApi.fetchHadiths(
      bookSlug: widget.bookSlug,
      chapterNumber: widget.chapter.chapterNumber,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.chapter.english,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    body: FutureBuilder<List<Hadith>>(
      future: _hadithsFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.hadithCard),
          );
        }
        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load this chapter',
            action: 'Try again',
            onAction: () => setState(_load),
          );
        }
        final hadiths = snapshot.data ?? const <Hadith>[];
        if (hadiths.isEmpty) {
          return const _StateMessage(
            icon: Icons.menu_book_outlined,
            title: 'No narrations in this chapter',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          itemCount: hadiths.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) => _HadithPreview(
            hadith: hadiths[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HadithDetailScreen(hadith: hadiths[index]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _HadithPreview extends StatelessWidget {
  const _HadithPreview({required this.hadith, required this.onTap});
  final Hadith hadith;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final english = hadith.english ?? '';
    final arabic = hadith.arabic ?? '';
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDCE6E3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.hadithCard.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${hadith.hadithNumber}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.hadithCard,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  english.isNotEmpty
                      ? english
                      : arabic.isNotEmpty
                      ? arabic
                      : 'Open narration',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textDirection: english.isEmpty
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: english.isEmpty
                      ? AppTextStyles.arabicMedium
                      : AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.55,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3,
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
