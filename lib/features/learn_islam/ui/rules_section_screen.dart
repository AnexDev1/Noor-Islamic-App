import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/learn_islam_provider.dart';

/// Card-based expandable sections covering the Five Pillars,
/// Six Articles of Faith, Islamic Etiquette, and Purification.
class RulesSectionScreen extends ConsumerWidget {
  const RulesSectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(islamicRulesProvider);
    final progress = ref.watch(learnProgressProvider);

    return rulesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sections) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          final sectionId = section['id'] as String;
          final isCompleted = progress.completedRuleSections.contains(
            sectionId,
          );
          final colorHex = section['color'] as String? ?? '#0F4C3A';
          final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
          final icon = _iconFromName(section['icon'] as String? ?? 'book');

          return _SectionCard(
            section: section,
            sectionId: sectionId,
            sectionColor: color,
            sectionIcon: icon,
            isCompleted: isCompleted,
            onMarkComplete: () {
              ref
                  .read(learnProgressProvider.notifier)
                  .completeRuleSection(sectionId);
              HapticFeedback.mediumImpact();
            },
          );
        },
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'mosque':
        return Icons.mosque;
      case 'favorite':
        return Icons.favorite;
      case 'handshake':
        return Icons.handshake;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.menu_book;
    }
  }
}

class _SectionCard extends StatefulWidget {
  final Map<String, dynamic> section;
  final String sectionId;
  final Color sectionColor;
  final IconData sectionIcon;
  final bool isCompleted;
  final VoidCallback onMarkComplete;

  const _SectionCard({
    required this.section,
    required this.sectionId,
    required this.sectionColor,
    required this.sectionIcon,
    required this.isCompleted,
    required this.onMarkComplete,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _isExpanded = false;
  int? _expandedItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items =
        (widget.section['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _isExpanded
                    ? LinearGradient(
                        colors: [
                          widget.sectionColor.withValues(alpha: 0.12),
                          widget.sectionColor.withValues(alpha: 0.04),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.sectionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.sectionIcon,
                      color: widget.sectionColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section['title'] ?? '',
                          style: AppTextStyles.heading3,
                        ),
                        Text(
                          l10n.topics(items.length),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  if (widget.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded items
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: AppColors.textTertiary.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final itemExpanded = _expandedItem == i;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: itemExpanded
                            ? widget.sectionColor.withValues(alpha: 0.04)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: itemExpanded
                            ? Border.all(
                                color: widget.sectionColor.withValues(
                                  alpha: 0.2,
                                ),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          // Item header
                          InkWell(
                            onTap: () => setState(() {
                              _expandedItem = itemExpanded ? null : i;
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.sectionColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] ?? '',
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (item['arabic'] != null)
                                          Text(
                                            item['arabic'],
                                            style: AppTextStyles.arabicSmall
                                                .copyWith(
                                                  fontSize: 13,
                                                  color: widget.sectionColor,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    itemExpanded ? Icons.remove : Icons.add,
                                    size: 18,
                                    color: AppColors.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Item content
                          if (itemExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    height: 1,
                                    color: AppColors.textTertiary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item['content'] ?? '',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.6,
                                    ),
                                  ),
                                  if (item['reference'] != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: widget.sectionColor.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.format_quote,
                                            size: 14,
                                            color: widget.sectionColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['reference'],
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color: widget.sectionColor,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  // Mark section as complete
                  if (!widget.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onMarkComplete,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(l10n.markSectionComplete),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.sectionColor,
                            side: BorderSide(
                              color: widget.sectionColor.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
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
