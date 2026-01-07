import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class QuranSettingsSheet extends StatelessWidget {
  final String selectedTranslationKey;
  final String selectedReciterId;
  final bool showTranslation;
  final Map<String, String> translationOptions;
  final Map<String, String> reciters;
  final Function(String?) onTranslationChanged;
  final Function(String?) onReciterChanged;
  final Function(bool) onShowTranslationChanged;

  const QuranSettingsSheet({
    super.key,
    required this.selectedTranslationKey,
    required this.selectedReciterId,
    required this.showTranslation,
    required this.translationOptions,
    required this.reciters,
    required this.onTranslationChanged,
    required this.onReciterChanged,
    required this.onShowTranslationChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required String selectedTranslationKey,
    required String selectedReciterId,
    required bool showTranslation,
    required Map<String, String> translationOptions,
    required Map<String, String> reciters,
    required Function(String?) onTranslationChanged,
    required Function(String?) onReciterChanged,
    required Function(bool) onShowTranslationChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuranSettingsSheet(
        selectedTranslationKey: selectedTranslationKey,
        selectedReciterId: selectedReciterId,
        showTranslation: showTranslation,
        translationOptions: translationOptions,
        reciters: reciters,
        onTranslationChanged: onTranslationChanged,
        onReciterChanged: onReciterChanged,
        onShowTranslationChanged: onShowTranslationChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reading Settings', style: AppTextStyles.heading3),
                      const SizedBox(height: 2),
                      Text(
                        'Customize your Quran reading experience',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Settings Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show Translation Toggle
                _buildToggleSetting(
                  context: context,
                  icon: Icons.translate_rounded,
                  title: 'Show Translation',
                  subtitle: 'Display translation alongside Arabic text',
                  value: showTranslation,
                  onChanged: (value) {
                    onShowTranslationChanged(value);
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 20),

                // Translation Language (only show if translation is enabled)
                if (showTranslation) ...[
                  _buildDropdownSetting(
                    context: context,
                    icon: Icons.language_rounded,
                    title: 'Translation Language',
                    value: selectedTranslationKey,
                    options: translationOptions,
                    onChanged: (value) {
                      onTranslationChanged(value);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Reciter Selection
                if (reciters.isNotEmpty)
                  _buildDropdownSetting(
                    context: context,
                    icon: Icons.record_voice_over_rounded,
                    title: 'Reciter',
                    value: selectedReciterId,
                    options: reciters,
                    onChanged: (value) {
                      onReciterChanged(value);
                      Navigator.pop(context);
                    },
                  ),

                const SizedBox(height: 24),

                // Quick tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Turn off translation for a focused Arabic reading experience',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Map<String, String> options,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: options.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value, style: AppTextStyles.bodyMedium),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
