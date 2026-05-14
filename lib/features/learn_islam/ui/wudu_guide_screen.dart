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
        itemCount: steps.length + 1,
        itemBuilder: (context, index) {
          if (index == steps.length) {
            return _buildQuizButton();
          }
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

  Widget _buildQuizButton() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 40),
      child: ElevatedButton.icon(
        onPressed: () => _showWuduQuiz(),
        icon: const Icon(Icons.quiz, size: 20),
        label: Text(l10n.testYourKnowledge),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF06B6D4), // waterColor
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF06B6D4).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  void _showWuduQuiz() {
    final l10n = AppLocalizations.of(context)!;
    int currentQuestion = 0;
    int score = 0;

    final questions = [
      {
        'q': 'What is the first and most important step before starting Wudu?',
        'options': ['Washing the hands', 'Making intention (Niyyah) & saying Bismillah', 'Rinsing the mouth', 'Washing the face'],
        'answer': 1,
      },
      {
        'q': 'How many times is it Sunnah to wash your arms up to the elbows?',
        'options': ['Once', 'Twice', 'Three times', 'Four times'],
        'answer': 2,
      },
      {
        'q': 'When washing your arms or feet, which side should you start with?',
        'options': ['The Left side', 'The Right side', 'Both at the same time', 'It doesn\'t matter'],
        'answer': 1,
      },
      {
        'q': 'How many times should you wipe your head (Masah)?',
        'options': ['Once', 'Twice', 'Three times', 'It is optional'],
        'answer': 0,
      },
      {
        'q': 'What is recommended to say after completing Wudu?',
        'options': ['Allahu Akbar', 'Alhamdulillah', 'The Shahadah', 'SubhanAllah'],
        'answer': 2,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (currentQuestion >= questions.length) {
              // Quiz complete
              Future.microtask(() {
                ref
                    .read(learnProgressProvider.notifier)
                    .recordQuizResult(score, questions.length);
              });
              return _quizResultSheet(score, questions.length, l10n);
            }

            final q = questions[currentQuestion];
            final options = q['options'] as List<String>;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.quiz,
                        style: AppTextStyles.heading3,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentQuestion + 1} / ${questions.length}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: const Color(0xFF06B6D4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    q['q'] as String,
                    style: AppTextStyles.heading4.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(options.length, (idx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () {
                          if (idx == q['answer']) {
                            score++;
                            HapticFeedback.lightImpact();
                          } else {
                            HapticFeedback.heavyImpact();
                          }
                          setSheetState(() {
                            currentQuestion++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.textTertiary.withValues(alpha: 0.2),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          options[idx],
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quizResultSheet(int score, int total, AppLocalizations l10n) {
    final percentage = ((score / total) * 100).round();
    final isGood = percentage >= 60;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isGood ? AppColors.success : AppColors.secondary)
                  .withValues(alpha: 0.1),
            ),
            child: Icon(
              isGood ? Icons.stars : Icons.refresh,
              size: 40,
              color: isGood ? AppColors.success : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$score / $total',
            style: AppTextStyles.displayMedium.copyWith(
              color: isGood ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quizResultMessage(score, total, percentage),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
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
