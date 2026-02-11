import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
  await FcmService._showLocalNotification(message);
}

/// Centralized FCM service for the Noor app.
///
/// Handles:
/// - Token registration & refresh
/// - Foreground, background, and terminated-state messages
/// - Topic subscriptions (daily_ayah, announcements, etc.)
/// - Deep-link routing from notification taps
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Notification channel for FCM push messages ──
  static const AndroidNotificationChannel _fcmChannel =
      AndroidNotificationChannel(
        'fcm_push_channel',
        'Push Notifications',
        description: 'Notifications from Noor cloud messaging',
        importance: Importance.high,
        playSound: true,
      );

  // ── Keys ──
  static const String _tokenKey = 'fcm_device_token';
  static const String _topicsKey = 'fcm_subscribed_topics';

  // ── Stream controller for navigation payloads ──
  static final StreamController<Map<String, dynamic>> _onNotificationTap =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Listen to this stream to navigate when user taps a notification.
  static Stream<Map<String, dynamic>> get onNotificationTap =>
      _onNotificationTap.stream;

  // ═══════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Call this once in main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    // 1. Request permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      provisional: false,
    );
    debugPrint('[FCM] Auth status: ${settings.authorizationStatus}');

    // 2. Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_fcmChannel);

    // 3. Init local notifications (for foreground display)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 4. Get & save token
    await _retrieveAndSaveToken();

    // 5. Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // 6. Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 7. When user taps notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 8. Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationPayload(initialMessage.data);
    }

    // 9. Subscribe to default topics
    await subscribeToTopic('daily_ayah');
    await subscribeToTopic('announcements');
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _retrieveAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        // TODO: Send token to your backend server
        // await ApiService.registerDeviceToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Token retrieval error: $e');
    }
  }

  static void _onTokenRefresh(String newToken) async {
    debugPrint('[FCM] Token refreshed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    // TODO: Update token on your backend
    // await ApiService.registerDeviceToken(newToken);
  }

  /// Returns the current FCM token (or null).
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ═══════════════════════════════════════════════════════════════
  //  MESSAGE HANDLERS
  // ═══════════════════════════════════════════════════════════════

  /// Shows a local notification when a message arrives while the app is in
  /// the foreground (Firebase doesn't auto-display on Android in foreground).
  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  /// When user taps a notification and app was in background.
  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from background: ${message.data}');
    _handleNotificationPayload(message.data);
  }

  /// Displays the remote message as a local notification.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _fcmChannel.id,
      _fcmChannel.name,
      channelDescription: _fcmChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  /// Called when user taps on the local notification.
  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationPayload(data);
      } catch (e) {
        debugPrint('[FCM] Payload parse error: $e');
      }
    }
  }

  /// Route the user based on notification payload data.
  static void _handleNotificationPayload(Map<String, dynamic> data) {
    _onNotificationTap.add(data);

    // Example routing logic:
    //   data = { "route": "learn_islam", "tab": "salah" }
    //   data = { "route": "tasbih_hub" }
    //   data = { "route": "ayah_card", "ayah_id": "1" }
    debugPrint('[FCM] Routing payload: $data');
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOPIC SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Subscribe to a topic (e.g. 'daily_ayah', 'announcements').
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      final prefs = await SharedPreferences.getInstance();
      final topics = prefs.getStringList(_topicsKey) ?? [];
      if (!topics.contains(topic)) {
        topics.add(topic);
        await prefs.setStringList(_topicsKey, topics);
      }
      debugPrint('[FCM] Subscribed to: $topic');
    } catch (e) {
      debugPrint('[FCM] Subscribe error for $topic: $e');
    }
  }

  /// Unsubscribe from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      final prefs = await SharedPreferences.getInstance();
      final topics = prefs.getStringList(_topicsKey) ?? [];
      topics.remove(topic);
      await prefs.setStringList(_topicsKey, topics);
      debugPrint('[FCM] Unsubscribed from: $topic');
    } catch (e) {
      debugPrint('[FCM] Unsubscribe error for $topic: $e');
    }
  }

  /// Returns the list of currently subscribed topics.
  static Future<List<String>> getSubscribedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_topicsKey) ?? [];
  }

  // ═══════════════════════════════════════════════════════════════
  //  CLEANUP
  // ═══════════════════════════════════════════════════════════════

  /// Delete the FCM token (e.g. on logout).
  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint('[FCM] Token deleted');
  }

  /// Dispose resources.
  static void dispose() {
    _onNotificationTap.close();
  }
}
