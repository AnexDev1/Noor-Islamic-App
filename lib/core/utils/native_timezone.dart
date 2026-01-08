import 'package:flutter/services.dart';

class NativeTimezone {
  static const MethodChannel _channel = MethodChannel('noor/native_timezone');

  /// Returns the device's local timezone identifier (IANA) when available.
  /// Falls back to [DateTime.now().timeZoneName] if the platform call fails.
  static Future<String> getLocalTimezone() async {
    try {
      final String? tz = await _channel.invokeMethod<String>(
        'getLocalTimezone',
      );
      if (tz != null && tz.isNotEmpty) return tz;
    } catch (_) {}
    return DateTime.now().timeZoneName;
  }
}
