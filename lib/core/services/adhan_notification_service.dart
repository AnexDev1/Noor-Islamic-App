import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/models.dart';

/// Service for managing Adhan (prayer call) notifications
/// Schedules notifications for prayer times and 15-minute reminders
class AdhanNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationsEnabledKey = 'adhan_notifications_enabled';
  static const String _reminderEnabledKey = 'prayer_reminder_enabled';

  // Notification channel IDs
  static const String _adhanChannelId = 'adhan_channel_custom_sound';
  static const String _reminderChannelId = 'reminder_channel';

  // Notification IDs for each prayer (base IDs)
  static const int _fajrId = 1;
  static const int _dhuhrId = 2;
  static const int _asrId = 3;
  static const int _maghribId = 4;
  static const int _ishaId = 5;

  // Reminder IDs are base + 100
  static const int _reminderOffset = 100;

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Adhan channel - high importance for prayer time
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _adhanChannelId,
          'Adhan Notifications',
          description: 'Notifications for prayer times',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('azan'),
          enableVibration: true,
        ),
      );

      // Reminder channel - default importance
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannelId,
          'Prayer Reminders',
          description: 'Reminders 15 minutes before prayer',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to prayer times screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Set notifications enabled/disabled
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Check if reminders are enabled
  static Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? true;
  }

  /// Set reminders enabled/disabled
  static Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
  }

  /// Schedule all prayer notifications for the day
  /// [prayerTimes] - Map of prayer names to time strings (e.g., "05:30")
  static Future<void> scheduleDailyPrayerNotificationsFromStrings({
    required String fajr,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
  }) async {
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    final remindersEnabled = await areRemindersEnabled();

    // Cancel existing notifications first
    await cancelAllNotifications();

    final now = DateTime.now();

    // Schedule each prayer
    await _schedulePrayerNotification(
      id: _fajrId,
      prayerName: 'Fajr',
      prayerNameArabic: 'الفجر',
      timeString: fajr,
      date: now,
      scheduleReminder: remindersEnabled,
    );

    await _schedulePrayerNotification(
      id: _dhuhrId,
      prayerName: 'Dhuhr',
      prayerNameArabic: 'الظهر',
      timeString: dhuhr,
      date: now,
      scheduleReminder: remindersEnabled,
    );

    await _schedulePrayerNotification(
      id: _asrId,
      prayerName: 'Asr',
      prayerNameArabic: 'العصر',
      timeString: asr,
      date: now,
      scheduleReminder: remindersEnabled,
    );

    await _schedulePrayerNotification(
      id: _maghribId,
      prayerName: 'Maghrib',
      prayerNameArabic: 'المغرب',
      timeString: maghrib,
      date: now,
      scheduleReminder: remindersEnabled,
    );

    await _schedulePrayerNotification(
      id: _ishaId,
      prayerName: 'Isha',
      prayerNameArabic: 'العشاء',
      timeString: isha,
      date: now,
      scheduleReminder: remindersEnabled,
    );

    debugPrint('Prayer notifications scheduled successfully');
  }

  /// Schedule all prayer notifications using PrayerTimes model
  static Future<void> scheduleDailyPrayerNotifications(
    PrayerTimes prayerTimes,
  ) async {
    await scheduleDailyPrayerNotificationsFromStrings(
      fajr: prayerTimes.fajr,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }

  /// Schedule a single prayer notification
  static Future<void> _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required String prayerNameArabic,
    required String timeString,
    required DateTime date,
    required bool scheduleReminder,
  }) async {
    try {
      final time = _parseTimeString(timeString);
      if (time == null) return;

      final scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // Only schedule if the time is in the future
      if (scheduledDateTime.isAfter(DateTime.now())) {
        // Schedule main adhan notification
        await _scheduleNotification(
          id: id,
          title: 'Time for $prayerName Prayer',
          body: '$prayerNameArabic - It\'s time to pray $prayerName',
          scheduledTime: scheduledDateTime,
          channelId: _adhanChannelId,
          payload: prayerName,
        );

        // Schedule 15-minute reminder if enabled
        if (scheduleReminder) {
          final reminderTime = scheduledDateTime.subtract(
            const Duration(minutes: 15),
          );
          if (reminderTime.isAfter(DateTime.now())) {
            await _scheduleNotification(
              id: id + _reminderOffset,
              title: '$prayerName Prayer in 15 minutes',
              body: 'Prepare for $prayerName prayer ($prayerNameArabic)',
              scheduledTime: reminderTime,
              channelId: _reminderChannelId,
              payload: '${prayerName}_reminder',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error scheduling $prayerName notification: $e');
    }
  }

  /// Schedule a notification at a specific time
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _adhanChannelId ? 'Adhan Notifications' : 'Prayer Reminders',
      channelDescription: channelId == _adhanChannelId
          ? 'Notifications for prayer times'
          : 'Reminders 15 minutes before prayer',
      importance: channelId == _adhanChannelId
          ? Importance.high
          : Importance.defaultImportance,
      priority: channelId == _adhanChannelId
          ? Priority.high
          : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      sound: channelId == _adhanChannelId
          ? const RawResourceAndroidNotificationSound('azan')
          : null,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Test adhan notification (immediate)
  static Future<void> testAdhanNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _adhanChannelId,
      'Adhan Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('azan'),
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Time for Fajr Prayer\nالفجر - It\'s time to pray Fajr',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Test ID
      'Time for Fajr Prayer',
      'الفجر - It\'s time to pray Fajr',
      details,
      payload: 'test_adhan',
    );
  }

  /// Test reminder notification (immediate)
  static Future<void> testReminderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Prayer Reminders',
      channelDescription: 'Reminders 15 minutes before prayer',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Fajr Prayer in 15 minutes\nPrepare for Fajr prayer (الفجر)',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1000, // Test ID
      'Fajr Prayer in 15 minutes',
      'Prepare for Fajr prayer (الفجر)',
      details,
      payload: 'test_reminder',
    );
  }

  static DateTime? _parseTimeString(String timeString) {
    try {
      // Remove any extra whitespace
      timeString = timeString.trim();

      int hour;
      int minute;

      // Check for AM/PM format
      if (timeString.toLowerCase().contains('am') ||
          timeString.toLowerCase().contains('pm')) {
        final isPM = timeString.toLowerCase().contains('pm');
        timeString = timeString
            .toLowerCase()
            .replaceAll('am', '')
            .replaceAll('pm', '')
            .trim();
        final parts = timeString.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      } else {
        // 24-hour format
        final parts = timeString.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }

      return DateTime(2024, 1, 1, hour, minute);
    } catch (e) {
      debugPrint('Error parsing time string: $timeString - $e');
      return null;
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel notifications for a specific prayer
  static Future<void> cancelPrayerNotification(int prayerId) async {
    await _notifications.cancel(prayerId);
    await _notifications.cancel(prayerId + _reminderOffset);
  }

  /// Show an immediate test notification
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _adhanChannelId,
      'Adhan Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification',
      'Adhan notifications are working correctly!',
      details,
    );
  }
}
