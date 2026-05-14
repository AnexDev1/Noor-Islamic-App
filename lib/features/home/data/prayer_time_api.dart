import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class PrayerTimeApi {
  static const MethodChannel _channel = MethodChannel('noor/widget');

  // Use the same calculation family as the native widget helper by default.
  static const String _baseUrl = 'https://api.aladhan.com/v1/timings/';

  // Default location: Mecca
  static const double _defaultLat = 21.4225;
  static const double _defaultLon = 39.8262;
  static const int _defaultMethod = 4; // Umm Al-Qura University, Makkah
  static const int _defaultSchool = 1; // Shafi

  // Fallback prayer times for Mecca (in case API fails)
  static const Map<String, String> _fallbackPrayerTimes = {
    'Fajr': '05:41',
    'Dhuhr': '12:26',
    'Asr': '15:32',
    'Maghrib': '17:53',
    'Isha': '19:08',
  };

  static Future<PrayerTimesResult> fetchPrayerTimes({
    double? lat,
    double? lon,
    int? method,
    int? school,
  }) async {
    final resolvedMethod = method ?? _defaultMethod;
    final resolvedSchool = school ?? _defaultSchool;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final nativeResult = await _channel.invokeMapMethod<String, dynamic>(
          'getPrayerTimes',
          {
            'latitude': lat ?? _defaultLat,
            'longitude': lon ?? _defaultLon,
            'method': _methodNameFor(resolvedMethod),
            'madhab': _schoolNameFor(resolvedSchool),
          },
        );

        if (nativeResult != null) {
          final timesMap = <String, String>{
            'Fajr': _normalizeTime(nativeResult['Fajr']),
            'Dhuhr': _normalizeTime(nativeResult['Dhuhr']),
            'Asr': _normalizeTime(nativeResult['Asr']),
            'Maghrib': _normalizeTime(nativeResult['Maghrib']),
            'Isha': _normalizeTime(nativeResult['Isha']),
          };
          if (timesMap.values.every((value) => value.isNotEmpty)) {
            return PrayerTimesResult(timesMap, false);
          }
        }
      } catch (e) {
        debugPrint('Native prayer time calculation failed: $e');
      }
    }

    final url = Uri.parse(
      '$_baseUrl${DateTime.now().millisecondsSinceEpoch ~/ 1000}?latitude=${lat ?? _defaultLat}&longitude=${lon ?? _defaultLon}&method=$resolvedMethod&school=$resolvedSchool',
    );

    // Try up to 3 times with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 200 && data['status'] == 'OK') {
            final timings = data['data']['timings'] as Map<String, dynamic>;
            // Only keep the main prayers
            final Map<String, String> timesMap = {
              'Fajr': _normalizeTime(timings['Fajr']),
              'Dhuhr': _normalizeTime(timings['Dhuhr']),
              'Asr': _normalizeTime(timings['Asr']),
              'Maghrib': _normalizeTime(timings['Maghrib']),
              'Isha': _normalizeTime(timings['Isha']),
            };
            return PrayerTimesResult(timesMap, false);
          } else {
            throw Exception(
              'API returned error: ${data['status'] ?? 'Unknown error'}',
            );
          }
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        if (attempt == 3) {
          // Last attempt failed - return fallback times
          return PrayerTimesResult(_fallbackPrayerTimes, true);
        } else {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    // This should never be reached, but just in case
    return PrayerTimesResult(_fallbackPrayerTimes, true);
  }

  static String _normalizeTime(dynamic value) {
    final raw = (value ?? '').toString().trim();
    final match = RegExp(r'^(\d{1,2}:\d{2})').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  static String _methodNameFor(int method) {
    switch (method) {
      case 4:
        return 'UMM_AL_QURA';
      case 5:
        return 'DUBAI';
      case 7:
        return 'KARACHI';
      case 8:
        return 'KUWAIT';
      case 9:
        return 'QATAR';
      case 10:
        return 'SINGAPORE';
      case 11:
        return 'MOON_SIGHTING';
      case 12:
        return 'MUSLIM_WORLD_LEAGUE';
      case 13:
        return 'EGYPTIAN';
      case 3:
      default:
        return 'MUSLIM_WORLD_LEAGUE';
    }
  }

  static String _schoolNameFor(int school) {
    return school == 0 ? 'HANAFI' : 'SHAFI';
  }
}

class PrayerTimesResult {
  final Map<String, String> times;
  final bool isUsingFallback;

  PrayerTimesResult(this.times, this.isUsingFallback);
}
