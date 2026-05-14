import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/bookmark_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../azkhar/data/azkhar_api.dart';
import '../../azkhar/ui/azkhar_detail_screen.dart';
import '../../hadith/data/hadiths_api.dart';
import '../../hadith/ui/hadith_detail_screen.dart';
import '../../quran/ui/surah_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    BookmarkService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookmarks', style: AppTextStyles.heading3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<BookmarkItem>>(
        valueListenable: BookmarkService.instance.bookmarks,
        builder: (context, bookmarks, _) {
          if (bookmarks.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              return _buildBookmarkCard(bookmarks[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: AppColors.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Items you bookmark in Quran, Hadith, or Azkhar will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(BookmarkItem item) {
    late final IconData typeIcon;
    late final Color typeColor;

    switch (item.type) {
      case BookmarkType.quran:
        typeIcon = Icons.menu_book_rounded;
        typeColor = AppColors.primary;
        break;
      case BookmarkType.hadith:
        typeIcon = Icons.auto_stories_rounded;
        typeColor = AppColors.accent;
        break;
      case BookmarkType.azkhar:
        typeIcon = Icons.wb_sunny_rounded;
        typeColor = Colors.orange;
        break;
      case BookmarkType.video:
        typeIcon = Icons.play_circle_filled_rounded;
        typeColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          item.title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.subtitle, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(item.timestamp),
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
          onPressed: () async {
            await BookmarkService.instance.removeBookmark(item.id, item.type);
          },
        ),
        onTap: () => _handleNavigation(item),
      ),
    );
  }

  Future<void> _handleNavigation(BookmarkItem item) async {
    switch (item.type) {
      case BookmarkType.quran:
        final surahNo = item.metadata['surahNo'] as int?;
        if (surahNo == null) {
          _showSnackBar('This Quran bookmark is missing its surah number.');
          return;
        }

        if (!mounted) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailScreen(
              surahNo: surahNo,
              surahName: item.title.split(' - ').first,
            ),
          ),
        );
        break;

      case BookmarkType.hadith:
        final bookSlug = item.metadata['bookSlug'] as String?;
        final hadithNumber = item.metadata['hadithNumber'] as int?;
        if (bookSlug == null || hadithNumber == null) {
          _showSnackBar('This Hadith bookmark is missing its reference.');
          return;
        }

        _showLoadingDialog();
        try {
          final hadiths = await HadithsApi.fetchHadiths(
            bookSlug: bookSlug,
            hadithNumber: hadithNumber,
          );

          if (!mounted) {
            return;
          }

          _dismissLoadingDialog();

          if (hadiths.isEmpty) {
            _showSnackBar('No Hadith details were found.');
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HadithDetailScreen(hadith: hadiths.first),
            ),
          );
        } catch (_) {
          if (mounted) {
            _dismissLoadingDialog();
            _showSnackBar('Failed to load Hadith details.');
          }
        }
        break;

      case BookmarkType.azkhar:
        final categoryName = item.metadata['category'] as String?;
        if (categoryName == null) {
          _showSnackBar('This Azkhar bookmark is missing its category.');
          return;
        }

        _showLoadingDialog();
        try {
          final categories = await AzkharApi.fetchCategories();

          if (!mounted) {
            return;
          }

          _dismissLoadingDialog();

          final category = categories
              .where((c) => c.name == categoryName)
              .toList();
          if (category.isEmpty) {
            _showSnackBar('Azkhar category not found.');
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AzkharDetailScreen(category: category.first),
            ),
          );
        } catch (_) {
          if (mounted) {
            _dismissLoadingDialog();
            _showSnackBar('Failed to load Azkar details.');
          }
        }
        break;

      case BookmarkType.video:
        _showSnackBar('Video bookmarks are not linked yet.');
        break;
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _dismissLoadingDialog() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
