import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../common_widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../logic/qadah_provider.dart';
import '../logic/qadah_notification_service.dart';
import '../data/qadah_model.dart';

class QadahScreen extends ConsumerStatefulWidget {
  const QadahScreen({super.key});

  @override
  ConsumerState<QadahScreen> createState() => _QadahScreenState();
}

class _QadahScreenState extends ConsumerState<QadahScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(qadahProvider);
    final notifier = ref.read(qadahProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: l10n.qadahTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero progress card
            _buildProgressCard(context, settings, l10n),
            const SizedBox(height: 24),

            // Action section (Increment)
            _buildActionSection(context, notifier, l10n),
            const SizedBox(height: 24),

            // Settings / Setup
            _buildSettingsSection(context, settings, notifier, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    QadahSettings settings,
    AppLocalizations l10n,
  ) {
    final double progress = settings.totalMissedDays == 0
        ? 0
        : (settings.totalPaidDays / settings.totalMissedDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.remainingDays,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${settings.remainingDays}',
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(l10n.totalMissed, '${settings.totalMissedDays}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(l10n.totalPaid, '${settings.totalPaidDays}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    QadahNotifier notifier,
    AppLocalizations l10n,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Track Today\'s Fast', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: l10n.incrementPaid,
              onPressed: () {
                notifier.incrementPaidDays();
                // Show confusion animation or snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mashallah! One day closer.')),
                );
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    QadahSettings settings,
    QadahNotifier notifier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setupQadah,
          style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        CustomCard(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.totalMissed),
                subtitle: Text(l10n.howManyMissed),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () =>
                      _showEditDaysDialog(context, settings, notifier),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.fastingReminders),
                value: settings.remindersEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  notifier.toggleReminders(val);
                },
              ),
              if (settings.remindersEnabled) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.remindMeOn, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: Days.values.map((day) {
                          final isSelected = settings.reminderDays.contains(
                            day,
                          );
                          // Localization for days would be ideal here
                          final dayName = day.name
                              .substring(0, 3)
                              .toUpperCase();

                          return FilterChip(
                            label: Text(dayName),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            onSelected: (_) => notifier.toggleReminderDay(day),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.reminderTime, style: AppTextStyles.bodyMedium),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          DateFormat.jm().format(settings.reminderTime),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              settings.reminderTime,
                            ),
                          );
                          if (picked != null) {
                            final now = DateTime.now();
                            notifier.setReminderTime(
                              DateTime(
                                now.year,
                                now.month,
                                now.day,
                                picked.hour,
                                picked.minute,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Create Reminder',
                          icon: const Icon(
                            Icons.add_alarm,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await notifier.saveReminders();
                            setState(
                              () {},
                            ); // Trigger refresh of future builder
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Reminders scheduled successfully!',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        "Active Reminders List",
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<PendingNotificationRequest>>(
                        future: QadahNotificationService.getPendingReminders(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final reminders = snapshot.data ?? [];
                          // Filter for Qadah IDs (200-207)
                          final qadahReminders = reminders
                              .where((r) => r.id >= 200 && r.id <= 207)
                              .toList();

                          if (qadahReminders.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "No active qadah reminders found.",
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: qadahReminders.map((r) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                color: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.notifications_active,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  title: Text(
                                    r.title ?? 'Fasting Reminder',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    r.body ?? 'Check your fasting schedule',
                                    style: AppTextStyles.caption,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await QadahNotificationService.cancelReminder(
                                        r.id,
                                      );
                                      setState(() {});
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDaysDialog(
    BuildContext context,
    QadahSettings settings,
    QadahNotifier notifier,
  ) {
    final controller = TextEditingController(
      text: settings.totalMissedDays.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Total Missed Days'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Days',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                notifier.setTotalMissedDays(val);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
