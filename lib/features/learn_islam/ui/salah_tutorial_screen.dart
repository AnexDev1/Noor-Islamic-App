import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/learn_islam_provider.dart';
import 'widgets/salah_illustrations.dart';

/// Interactive step-by-step Salah tutorial with expandable cards,
/// Arabic text, transliteration, translation, and retention quizzes.
class SalahTutorialScreen extends ConsumerStatefulWidget {
  const SalahTutorialScreen({super.key});

  @override
  ConsumerState<SalahTutorialScreen> createState() =>
      _SalahTutorialScreenState();
}

class _SalahTutorialScreenState extends ConsumerState<SalahTutorialScreen> {
  int? _expandedStep;

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(salahStepsProvider);
    final progress = ref.watch(learnProgressProvider);
    final l10n = AppLocalizations.of(context)!;

    return stepsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (steps) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: steps.length + 1, // +1 for quiz button at end
        itemBuilder: (context, index) {
          if (index == steps.length) {
            return _buildQuizButton(l10n);
          }

          final step = steps[index];
          final stepNum = step['step'] as int;
          final isCompleted = progress.completedSalahSteps.contains(stepNum);
          final isExpanded = _expandedStep == index;

          return _buildStepCard(
            step,
            stepNum,
            isCompleted,
            isExpanded,
            index,
            l10n,
          );
        },
      ),
    );
  }

  Widget _buildStepCard(
    Map<String, dynamic> step,
    int stepNum,
    bool isCompleted,
    bool isExpanded,
    int index,
    AppLocalizations l10n,
  ) {
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
                    ? AppColors.primary.withValues(alpha: 0.4)
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
          // Header (always visible)
          InkWell(
            onTap: () => setState(() {
              _expandedStep = isExpanded ? null : index;
            }),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step number circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.primary.withValues(alpha: 0.1),
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
                                color: AppColors.primary,
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
                            color: AppColors.primary,
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
                  // Position illustration
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: salahStepIllustration(stepNum, size: 140),
                    ),
                  ),

                  // Description
                  Text(
                    step['description'] ?? '',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Arabic du'a card
                  if (step['duaArabic'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.accent.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            step['duaArabic'],
                            style: AppTextStyles.arabicMedium.copyWith(
                              height: 2.2,
                              color: AppColors.textPrimary,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Transliteration
                          if (step['duaTransliteration'] != null) ...[
                            Text(
                              step['duaTransliteration'],
                              style: AppTextStyles.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Translation
                          Text(
                            step['duaTranslation'] ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: AppColors.accent,
                            ),
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

                  // Mark as completed button
                  if (!isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(learnProgressProvider.notifier)
                              .completeSalahStep(stepNum);
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(l10n.markAsLearned),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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

  Widget _buildQuizButton(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      child: ElevatedButton.icon(
        onPressed: () => _showSalahQuiz(),
        icon: const Icon(Icons.quiz, size: 20),
        label: Text(l10n.testYourKnowledge),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  void _showSalahQuiz() {
    final l10n = AppLocalizations.of(context)!;
    const questions = [
      {
        'q': 'What do you say when beginning the prayer?',
        'options': ['Bismillah', 'Allahu Akbar', 'SubhanAllah', 'Ameen'],
        'answer': 1,
      },
      {
        'q': 'Which surah is obligatory in every rak\'ah?',
        'options': ['Al-Ikhlas', 'Al-Baqarah', 'Al-Fatiha', 'Yaseen'],
        'answer': 2,
      },
      {
        'q': 'What do you say in Ruku (bowing)?',
        'options': [
          'SubhanAllah',
          'Subhana Rabbiyal Adheem',
          'Allahu Akbar',
          'Subhana Rabbiyal A\'la',
        ],
        'answer': 1,
      },
      {
        'q': 'What do you say in Sujud (prostration)?',
        'options': [
          'Subhana Rabbiyal Adheem',
          'Ameen',
          'Subhana Rabbiyal A\'la',
          'Alhamdulillah',
        ],
        'answer': 2,
      },
      {
        'q': 'How do you end the prayer?',
        'options': [
          'Say Allahu Akbar',
          'Clap your hands',
          'Turn head right then left saying Salam',
          'Stand up silently',
        ],
        'answer': 2,
      },
    ];

    int currentQ = 0;
    int score = 0;
    bool didRecordResult = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (currentQ >= questions.length) {
              // Quiz complete
              if (!didRecordResult) {
                didRecordResult = true;
                Future.microtask(() {
                  ref
                      .read(learnProgressProvider.notifier)
                      .recordQuizResult(score, questions.length);
                });
              }
              return _quizResultSheet(score, questions.length, l10n);
            }

            final q = questions[currentQ];
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  Row(
                    children: [
                      Text(
                        'Question ${currentQ + 1}/${questions.length}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Score: $score',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentQ + 1) / questions.length,
                      backgroundColor: AppColors.textTertiary.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(q['q'] as String, style: AppTextStyles.heading3),
                  const SizedBox(height: 16),
                  ...(q['options'] as List).asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          if (entry.key == q['answer']) score++;
                          setModalState(() => currentQ++);
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textTertiary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quizResultSheet(int score, int total, AppLocalizations l10n) {
    final percentage = (score / total * 100).round();
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percentage >= 80
                ? Icons.emoji_events
                : (percentage >= 60 ? Icons.thumb_up : Icons.refresh),
            size: 56,
            color: percentage >= 80
                ? AppColors.accent
                : (percentage >= 60
                      ? AppColors.success
                      : AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            percentage >= 80
                ? l10n.excellent
                : (percentage >= 60 ? l10n.goodJob : l10n.keepLearning),
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quizResultMessage(score, total, percentage),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.done),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
