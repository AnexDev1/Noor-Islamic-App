import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class AyahNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'ayah_channel';
  static const String _channelName = 'Ayah Notifications';
  static const String _channelDescription = 'Daily Ayah notifications';

  /// Schedules Ayah notifications for the next 7 days
  /// Requires AdhanNotificationService (or similar) to have initialized timezone
  static Future<void> scheduleUpcomingAyahs() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/ayah_collection.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      if (jsonList.isEmpty) return;

      final now = DateTime.now();

      // Schedule for the next 7 days
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));

        // Calculate the specific ayah for this date (must match AyahProvider logic)
        final startOfYear = DateTime(date.year, 1, 1);
        final dayIndex = date.difference(startOfYear).inDays;
        final ayahIndex = dayIndex % jsonList.length;

        final ayahData = jsonList[ayahIndex];
        final surah = ayahData['surah'];
        final ayahNum = ayahData['ayah'];
        // Use 'en' for translation as fixed in the provider
        final text = ayahData['en'] ?? ayahData['translation'] ?? '';

        final title = "Ayah of the Day";
        final body = "$surah $ayahNum: $text";

        // Schedule Morning (8:00 AM)
        final morningDate = _createDate(date, 8);
        if (morningDate != null) {
          await _scheduleNotification(
            id: 8000 + i,
            title: title,
            body: body,
            scheduledDate: morningDate,
          );
        }

        // Schedule Evening (8:00 PM / 20:00)
        final eveningDate = _createDate(date, 20);
        if (eveningDate != null) {
          await _scheduleNotification(
            id: 9000 + i,
            title: title,
            body: body,
            scheduledDate: eveningDate,
          );
        }
      }
      debugPrint("Scheduled Ayah notifications for next 7 days");
    } catch (e) {
      debugPrint("Error scheduling ayah notifications: $e");
    }
  }

  static tz.TZDateTime? _createDate(DateTime originalDate, int hour) {
    try {
      final location = tz.local;
      final target = tz.TZDateTime(
        location,
        originalDate.year,
        originalDate.month,
        originalDate.day,
        hour,
      );

      // If the time has already passed for today, don't schedule it
      if (target.isBefore(tz.TZDateTime.now(location))) {
        return null;
      }
      return target;
    } catch (e) {
      debugPrint("Error creating date for notification: $e");
      return null;
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.dateAndTime, // One-time event per ID
    );
  }
}
