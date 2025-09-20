import 'package:flutter/material.dart';
import '../../domain/azkhar_category.dart';
import '../azkhar_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ModernAzkharCategoryList extends StatelessWidget {
  final List<AzkharCategory> categories;

  const ModernAzkharCategoryList({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = categories[index];
          final itemCount = category.items.length;

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
                    builder: (_) => AzkharDetailScreen(category: category),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Category Icon with Gradient Background
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
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(category.name),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Category Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Arabic Name
                          Text(
                            category.name,
                            style: AppTextStyles.arabicMedium.copyWith(
                              fontSize: 20,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // English Translation
                          Text(
                            _getCategoryTranslation(category.name),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Item Count Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.format_list_numbered,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$itemCount azkar',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
        childCount: categories.length,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('صباح') || name.contains('morning')) {
      return Icons.wb_sunny;
    } else if (name.contains('مساء') || name.contains('evening')) {
      return Icons.brightness_3;
    } else if (name.contains('نوم') || name.contains('sleep')) {
      return Icons.bedtime;
    } else if (name.contains('صلاة') || name.contains('prayer')) {
      return Icons.mosque;
    } else if (name.contains('طعام') || name.contains('food')) {
      return Icons.restaurant;
    } else if (name.contains('سفر') || name.contains('travel')) {
      return Icons.flight_takeoff;
    } else if (name.contains('مطر') || name.contains('rain')) {
      return Icons.cloud;
    } else if (name.contains('وضوء') || name.contains('wudu')) {
      return Icons.wash;
    } else if (name.contains('مسجد') || name.contains('mosque')) {
      return Icons.place;
    } else if (name.contains('تسبيح') || name.contains('tasbeeh')) {
      return Icons.radio_button_checked;
    } else {
      return Icons.favorite;
    }
  }

  String _getCategoryTranslation(String categoryName) {
    final translations = {
      'أذكار الصباح': 'Morning Remembrance',
      'أذكار المساء': 'Evening Remembrance',
      'أذكار النوم': 'Before Sleep',
      'أذكار الاستيقاظ من النوم': 'Upon Waking Up',
      'دعاء ختم المجلس': 'End of Gathering',
      'أذكار الوضوء': 'During Ablution',
      'أذكار الصلاة': 'Prayer Remembrance',
      'أذكار بعد السلام من الصلاة': 'After Prayer',
      'أذكار الطعام': 'Before & After Meals',
      'أذكار السفر': 'Travel Supplications',
      'أذكار دخول المسجد': 'Entering Mosque',
      'أذكار الخروج من المسجد': 'Leaving Mosque',
      'دعاء المطر': 'Rain Supplications',
      'أذكار متفرقة': 'Various Remembrance',
      'التسبيح': 'Glorification',
    };

    return translations[categoryName] ?? 'Islamic Remembrance';
  }
}
