import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/qadah_model.dart';
import '../../../core/providers/app_providers.dart';
import 'qadah_notification_service.dart';

class QadahNotifier extends StateNotifier<QadahSettings> {
  final SharedPreferences _prefs;
  static const String _key = 'qadah_settings';

  QadahNotifier(this._prefs)
    : super(QadahSettings(reminderTime: DateTime(0, 1, 1, 20, 0))) {
    // Default 8 PM
    _loadSettings();
  }

  void _loadSettings() {
    final String? jsonStr = _prefs.getString(_key);
    if (jsonStr != null) {
      try {
        state = QadahSettings.fromJson(jsonDecode(jsonStr));
        // Ensure scheduled notifications match loaded state
        QadahNotificationService.scheduleQadahReminders(state);
      } catch (e) {
        // Fallback or error handling
      }
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
    // Schedule/Reschedule notifications whenever settings change
    await QadahNotificationService.scheduleQadahReminders(state);
  }

  Future<void> setTotalMissedDays(int days) async {
    state = state.copyWith(totalMissedDays: days);
    await _saveSettings();
  }

  Future<void> incrementPaidDays() async {
    if (state.remainingDays > 0) {
      state = state.copyWith(totalPaidDays: state.totalPaidDays + 1);
      await _saveSettings();
    }
  }

  Future<void> decrementPaidDays() async {
    if (state.totalPaidDays > 0) {
      state = state.copyWith(totalPaidDays: state.totalPaidDays - 1);
      await _saveSettings();
    }
  }

  Future<void> toggleReminderDay(Days day) async {
    final days = List<Days>.from(state.reminderDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(reminderDays: days);
    // Don't save immediately, wait for explicit 'Create/Save' action
  }

  Future<void> setReminderTime(DateTime time) async {
    state = state.copyWith(reminderTime: time);
    // Don't save immediately
  }

  Future<void> saveReminders() async {
    await _saveSettings();
  }

  Future<void> toggleReminders(bool enabled) async {
    state = state.copyWith(remindersEnabled: enabled);
    await _saveSettings();
  }
}

final qadahProvider = StateNotifierProvider<QadahNotifier, QadahSettings>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QadahNotifier(prefs);
});
