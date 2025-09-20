import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/azkhar_category.dart';
import '../domain/azkhar_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AzkharDetailScreen extends StatefulWidget {
  final AzkharCategory category;
  const AzkharDetailScreen({super.key, required this.category});

  @override
  State<AzkharDetailScreen> createState() => _AzkharDetailScreenState();
}

class _AzkharDetailScreenState extends State<AzkharDetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Map<int, int> _counters = {};
  bool _showArabic = true;
  bool _showBenefits = true;
  bool _showReference = true;

  @override
  void initState() {
    super.initState();

    // Initialize counters for each azkar
    for (int i = 0; i < widget.category.items.length; i++) {
      _counters[i] = widget.category.items[i].count;
    }

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _decrementCounter(int index) {
    if (_counters[index]! > 0) {
      setState(() {
        _counters[index] = _counters[index]! - 1;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Show completion message when counter reaches 0
      if (_counters[index] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Alhamdulillah! Completed this dhikr'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _resetCounter(int index) {
    setState(() {
      _counters[index] = widget.category.items[index].count;
    });
    HapticFeedback.mediumImpact();
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

    return translations[widget.category.name] ?? 'Islamic Remembrance';
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

            // Progress Summary
            SliverToBoxAdapter(
              child: _buildProgressSummary(),
            ),

            // Azkar List
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = widget.category.items[index];
                    final currentCount = _counters[index]!;
                    final isCompleted = currentCount == 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isCompleted
                            ? Border.all(color: AppColors.success, width: 2)
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with counter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isCompleted
                                          ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                                          : [AppColors.primary, AppColors.primaryLight],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Completed ✓' : 'Dhikr ${index + 1}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _copyToClipboard(item.content),
                                      icon: Icon(
                                        Icons.copy,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _resetCounter(index),
                                      icon: Icon(
                                        Icons.refresh,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Arabic Text
                            if (_showArabic)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: SelectableText(
                                  item.content,
                                  style: AppTextStyles.arabicLarge.copyWith(
                                    fontSize: 22,
                                    height: 2.0,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),

                            // Reference
                            if (_showReference && item.reference.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.book,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'المصدر: ',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.reference,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primary,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Benefits
                            if (_showBenefits && item.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb,
                                      color: AppColors.success,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'الفضل: ',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.description,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.success,
                                          height: 1.5,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Counter Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isCompleted
                                      ? [AppColors.success.withValues(alpha: 0.1), AppColors.success.withValues(alpha: 0.05)]
                                      : [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCompleted
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Repetition Count',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '$currentCount / ${item.count}',
                                        style: AppTextStyles.displayMedium.copyWith(
                                          color: isCompleted ? AppColors.success : AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Tap Button
                                  InkWell(
                                    onTap: currentCount > 0 ? () => _decrementCounter(index) : null,
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isCompleted
                                              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                                              : currentCount > 0
                                                  ? [AppColors.primary, AppColors.primaryLight]
                                                  : [AppColors.textTertiary, AppColors.textTertiary.withValues(alpha: 0.8)],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isCompleted ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isCompleted ? Icons.check : Icons.touch_app,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: widget.category.items.length,
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
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
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Reset all counters
            setState(() {
              for (int i = 0; i < widget.category.items.length; i++) {
                _counters[i] = widget.category.items[i].count;
              }
            });
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category.name,
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getCategoryTranslation(widget.category.name),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
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
            'Display Settings',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),

          // Toggle switches
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildToggleChip(
                label: 'Arabic',
                icon: Icons.text_format,
                isActive: _showArabic,
                onTap: () => setState(() => _showArabic = !_showArabic),
                color: AppColors.accent,
              ),
              _buildToggleChip(
                label: 'Benefits',
                icon: Icons.lightbulb,
                isActive: _showBenefits,
                onTap: () => setState(() => _showBenefits = !_showBenefits),
                color: AppColors.success,
              ),
              _buildToggleChip(
                label: 'Reference',
                icon: Icons.book,
                isActive: _showReference,
                onTap: () => setState(() => _showReference = !_showReference),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.textTertiary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : AppColors.textTertiary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isActive ? color : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    int completedCount = _counters.values.where((count) => count == 0).length;
    int totalCount = widget.category.items.length;
    double progress = totalCount > 0 ? completedCount / totalCount : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: AppTextStyles.heading4,
                  ),
                  Text(
                    '$completedCount of $totalCount completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
