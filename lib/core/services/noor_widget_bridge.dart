import 'package:flutter/services.dart';

/// Dart-side bridge for communicating with native Android widgets.
///
/// Sends location, settings, and refresh commands to the Kotlin widget code
/// via a MethodChannel (`noor/widget`).
///
/// Usage:
/// ```dart
/// await NoorWidgetBridge.updateLocation(
///   latitude: 21.4225,
///   longitude: 39.8262,
///   city: 'Mecca',
/// );
/// ```
class NoorWidgetBridge {
  static const _channel = MethodChannel('noor/widget');

  /// Push the user's current location so widgets can compute prayer times.
  static Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    String? city,
  }) async {
    final result = await _channel.invokeMethod<bool>('updateLocation', {
      'latitude': latitude,
      'longitude': longitude,
      if (city != null) 'city': city,
    });
    return result ?? false;
  }

  /// Set the prayer-time calculation method.
  ///
  /// Valid methods: `UMM_AL_QURA`, `MUSLIM_WORLD_LEAGUE`, `EGYPTIAN`,
  /// `KARACHI`, `DUBAI`, `NORTH_AMERICA`, `KUWAIT`, `QATAR`,
  /// `SINGAPORE`, `MOON_SIGHTING`.
  ///
  /// Valid madhabs: `SHAFI`, `HANAFI`.
  static Future<bool> setCalculationMethod({
    String? method,
    String? madhab,
  }) async {
    final result = await _channel.invokeMethod<bool>('setCalculationMethod', {
      if (method != null) 'method': method,
      if (madhab != null) 'madhab': madhab,
    });
    return result ?? false;
  }

  /// Set the widget display locale (`en` or `ar`).
  static Future<bool> setLocale(String locale) async {
    final result = await _channel.invokeMethod<bool>('setLocale', {
      'locale': locale,
    });
    return result ?? false;
  }

  /// Set the widget theme: `light`, `dark`, or `auto`.
  static Future<bool> setTheme(String theme) async {
    final result = await _channel.invokeMethod<bool>('setTheme', {
      'theme': theme,
    });
    return result ?? false;
  }

  /// Manually refresh all home-screen widgets immediately.
  static Future<bool> refreshWidgets() async {
    final result = await _channel.invokeMethod<bool>('refreshWidgets');
    return result ?? false;
  }

  /// Ensure WorkManager + AlarmManager schedules are running.
  /// Call once during app startup.
  static Future<bool> ensureScheduled() async {
    final result = await _channel.invokeMethod<bool>('ensureScheduled');
    return result ?? false;
  }
}
