import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../book_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ModernHadithBookList extends StatelessWidget {
  final List<HadithBook> books;

  const ModernHadithBookList({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final book = books[index];

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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(book: book),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Book Icon with Gradient Background
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Book Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Book Name
                          Text(
                            book.name,
                            style: AppTextStyles.heading4.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Author
                          if (book.writer != null && book.writer!.isNotEmpty)
                            Text(
                              'By ${book.writer}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Stats Row
                          Row(
                            children: [
                              if (book.chaptersCount != null)
                                _buildStatChip(
                                  icon: Icons.format_list_numbered,
                                  label: '${book.chaptersCount} chapters',
                                  color: AppColors.primary,
                                ),
                              if (book.chaptersCount != null && book.hadithsCount != null)
                                const SizedBox(width: 8),
                              if (book.hadithsCount != null)
                                _buildStatChip(
                                  icon: Icons.format_quote,
                                  label: '${book.hadithsCount} hadiths',
                                  color: AppColors.accent,
                                ),
                            ],
                          ),

                          if (book.writerDeath != null && book.writerDeath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Death: ${book.writerDeath}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Arrow Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: books.length,
      ),
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
