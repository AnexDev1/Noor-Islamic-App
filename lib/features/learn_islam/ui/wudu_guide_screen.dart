import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/learn_islam_provider.dart';
import 'widgets/wudu_illustrations.dart';

/// Step-by-step wudu guide with expandable cards, du'a text,
/// and "mark as learned" tracking.
class WuduGuideScreen extends ConsumerStatefulWidget {
  const WuduGuideScreen({super.key});

  @override
  ConsumerState<WuduGuideScreen> createState() => _WuduGuideScreenState();
}

class _WuduGuideScreenState extends ConsumerState<WuduGuideScreen> {
  int? _expandedStep;

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(wuduStepsProvider);
    final progress = ref.watch(learnProgressProvider);

    return stepsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error loading wudu steps: $e')),
      data: (steps) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          final stepNum = step['step'] as int;
          final isCompleted = progress.completedWuduSteps.contains(stepNum);
          final isExpanded = _expandedStep == index;

          return _WuduStepCard(
            step: step,
            stepNum: stepNum,
            isCompleted: isCompleted,
            isExpanded: isExpanded,
            onToggle: () => setState(() {
              _expandedStep = isExpanded ? null : index;
            }),
            onComplete: () {
              ref
                  .read(learnProgressProvider.notifier)
                  .completeWuduStep(stepNum);
              HapticFeedback.mediumImpact();
            },
          );
        },
      ),
    );
  }
}

class _WuduStepCard extends StatelessWidget {
  final Map<String, dynamic> step;
  final int stepNum;
  final bool isCompleted;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onComplete;

  const _WuduStepCard({
    required this.step,
    required this.stepNum,
    required this.isCompleted,
    required this.isExpanded,
    required this.onToggle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Water-themed accent color
    const waterColor = Color(0xFF06B6D4);
    final l10n = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : (isExpanded
                    ? waterColor.withValues(alpha: 0.4)
                    : AppColors.textTertiary.withValues(alpha: 0.1)),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step number / check
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isCompleted
                          ? LinearGradient(
                              colors: [
                                AppColors.success,
                                AppColors.success.withValues(alpha: 0.8),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                waterColor.withValues(alpha: 0.15),
                                waterColor.withValues(alpha: 0.08),
                              ],
                            ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '$stepNum',
                              style: AppTextStyles.heading4.copyWith(
                                color: waterColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] ?? '',
                          style: AppTextStyles.heading4,
                        ),
                        Text(
                          step['arabicTitle'] ?? '',
                          style: AppTextStyles.arabicSmall.copyWith(
                            color: waterColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: AppColors.textTertiary.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step illustration
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF06B6D4,
                          ).withValues(alpha: 0.08),
                        ),
                      ),
                      child: wuduStepIllustration(stepNum, size: 140),
                    ),
                  ),

                  Text(
                    step['description'] ?? '',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Du'a card (if exists)
                  if (step['duaArabic'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            waterColor.withValues(alpha: 0.08),
                            AppColors.accent.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: waterColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            step['duaArabic'],
                            style: AppTextStyles.arabicMedium.copyWith(
                              height: 2.2,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                          if (step['duaTransliteration'] != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              step['duaTransliteration'],
                              style: AppTextStyles.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: waterColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (step['duaTranslation'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              step['duaTranslation'],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Details
                  if (step['details'] != null) ...[
                    Text(
                      l10n.details,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['details'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Tips
                  if (step['tips'] != null) ...[
                    Text(
                      l10n.tips,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(step['tips'] as List).map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.water_drop, size: 16, color: waterColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip.toString(),
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Mark as completed
                  if (!isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(l10n.markAsLearned),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: waterColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.learned,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
