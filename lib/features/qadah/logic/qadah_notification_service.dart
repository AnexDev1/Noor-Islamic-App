import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/qadah_model.dart';

class QadahNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> scheduleQadahReminders(QadahSettings settings) async {
    // 1. Cancel existing Qadah reminders
    await _cancelAllQadahNotifications();

    if (!settings.remindersEnabled || settings.remainingDays <= 0) return;

    // 2. Schedule for selected days
    for (final day in settings.reminderDays) {
      await _scheduleWeeklyNotification(day, settings.reminderTime);
    }
  }

  static Future<void> _cancelAllQadahNotifications() async {
    // Cancel IDs range 200-207 (arbitrary range for Qadah)
    for (int i = 200; i <= 207; i++) {
      await _notifications.cancel(i);
    }
  }

  static Future<void> _scheduleWeeklyNotification(
    Days day,
    DateTime time,
  ) async {
    // Day.monday index is 0.
    // Convert Day enum to DateTime weekday (Monday=1...Sunday=7)
    final targetWeekday = day.index + 1;

    // "Remind 1 day ahead".
    // If the user selects Monday to fast, they need a reminder on Sunday.
    // So if target fast day is Mon(1), reminder is Sun(7).
    int reminderWeekday = targetWeekday - 1;
    if (reminderWeekday == 0) reminderWeekday = 7;

    final id = 200 + reminderWeekday;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Create candidate date for today with the target time
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If scheduled date is today but passed, or if today is not the correct weekday, adjust.
    // First, find the next occurrence of reminderWeekday
    while (scheduledDate.weekday != reminderWeekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the calculated day is today but time has passed, add 7 days (next week)
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    // Notification Details
    const androidDetails = AndroidNotificationDetails(
      'qadah_reminder_channel',
      'Qadah Fasting Reminders',
      channelDescription: 'Reminders to fast for Qadah',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound('azan'),
    );

    const iosDetails = DarwinNotificationDetails(sound: 'azan.mp3');

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule
    await _notifications.zonedSchedule(
      id,
      'Fasting Reminder',
      'Don\'t forget to fast tomorrow (Qadah)!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }
}
