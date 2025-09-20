import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/hadith.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HadithDetailScreen extends StatefulWidget {
  final Hadith hadith;
  const HadithDetailScreen({super.key, required this.hadith});

  @override
  State<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends State<HadithDetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showArabic = true;
  bool _showEnglish = true;
  bool _showUrdu = true;

  @override
  void initState() {
    super.initState();
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
        content: Text('Copied to clipboard'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _shareHadith() {
    String hadithText = 'Hadith ${widget.hadith.hadithNumber}\n\n';

    if (widget.hadith.arabic != null && widget.hadith.arabic!.isNotEmpty) {
      hadithText += '${widget.hadith.arabic}\n\n';
    }

    if (widget.hadith.english != null && widget.hadith.english!.isNotEmpty) {
      hadithText += '${widget.hadith.english}\n\n';
    }

    hadithText += 'Source: ${widget.hadith.bookSlug}';

    // Share functionality would go here
    _copyToClipboard(hadithText);
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
              child: _buildHadithContent(),
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
      actions: [
        IconButton(
          onPressed: _shareHadith,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.share,
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
                AppColors.hadithCard,
                AppColors.hadithCard.withOpacity(0.8),
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
                          '${widget.hadith.hadithNumber}',
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
                              'Hadith ${widget.hadith.hadithNumber}',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chapter ${widget.hadith.chapterNumber}',
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
            'Display Settings',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),

          // Language toggles
          Row(
            children: [
              Expanded(
                child: _buildToggleChip(
                  label: 'Arabic',
                  icon: Icons.text_format,
                  isActive: _showArabic,
                  onTap: () => setState(() => _showArabic = !_showArabic),
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleChip(
                  label: 'English',
                  icon: Icons.translate,
                  isActive: _showEnglish,
                  onTap: () => setState(() => _showEnglish = !_showEnglish),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleChip(
                  label: 'Urdu',
                  icon: Icons.language,
                  isActive: _showUrdu,
                  onTap: () => setState(() => _showUrdu = !_showUrdu),
                  color: AppColors.secondary,
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.textTertiary,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? color : AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? color : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hadith Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.hadithCard.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.hadithCard.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.hadithCard.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.format_quote,
                    color: AppColors.hadithCard,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hadith ${widget.hadith.hadithNumber}',
                        style: AppTextStyles.heading2,
                      ),
                      Text(
                        'Book: ${widget.hadith.bookSlug} • Chapter: ${widget.hadith.chapterNumber}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.hadith.status != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.hadith.status!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Arabic Text
          if (_showArabic && widget.hadith.arabic != null && widget.hadith.arabic!.isNotEmpty)
            _buildTextSection(
              title: 'Arabic Text',
              text: widget.hadith.arabic!,
              style: AppTextStyles.arabicLarge.copyWith(
                height: 2.0,
                fontSize: 24,
              ),
              isRtl: true,
              backgroundColor: AppColors.accent.withOpacity(0.05),
              borderColor: AppColors.accent.withOpacity(0.2),
              icon: Icons.text_format,
              iconColor: AppColors.accent,
            ),

          // English Translation
          if (_showEnglish && widget.hadith.english != null && widget.hadith.english!.isNotEmpty)
            _buildTextSection(
              title: 'English Translation',
              text: widget.hadith.english!,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.7,
                fontSize: 18,
              ),
              backgroundColor: AppColors.primary.withOpacity(0.05),
              borderColor: AppColors.primary.withOpacity(0.2),
              icon: Icons.translate,
              iconColor: AppColors.primary,
            ),

          // Urdu Translation
          if (_showUrdu && widget.hadith.urdu != null && widget.hadith.urdu!.isNotEmpty)
            _buildTextSection(
              title: 'Urdu Translation',
              text: widget.hadith.urdu!,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.8,
                fontSize: 18,
              ),
              isRtl: true,
              backgroundColor: AppColors.secondary.withOpacity(0.05),
              borderColor: AppColors.secondary.withOpacity(0.2),
              icon: Icons.language,
              iconColor: AppColors.secondary,
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTextSection({
    required String title,
    required String text,
    required TextStyle style,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    bool isRtl = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: iconColor,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _copyToClipboard(text),
              icon: Icon(
                Icons.copy,
                color: iconColor,
                size: 20,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: SelectableText(
            text,
            style: style,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
