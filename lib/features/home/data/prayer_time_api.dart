import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class PrayerTimeApi {
  // Using Aladhan API which is free and doesn't require API key
  static const String _baseUrl = 'https://api.aladhan.com/v1/timings/';

  // Default location: Mecca
  static const double _defaultLat = 21.4225;
  static const double _defaultLon = 39.8262;
  static const int _defaultMethod = 3; // Muslim World League
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
    final url = Uri.parse(
      '${_baseUrl}${DateTime.now().millisecondsSinceEpoch ~/ 1000}?latitude=${lat ?? _defaultLat}&longitude=${lon ?? _defaultLon}&method=${method ?? _defaultMethod}&school=${school ?? _defaultSchool}',
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
              'Fajr': (timings['Fajr'] ?? '').toString(),
              'Dhuhr': (timings['Dhuhr'] ?? '').toString(),
              'Asr': (timings['Asr'] ?? '').toString(),
              'Maghrib': (timings['Maghrib'] ?? '').toString(),
              'Isha': (timings['Isha'] ?? '').toString(),
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
}

class PrayerTimesResult {
  final Map<String, String> times;
  final bool isUsingFallback;

  PrayerTimesResult(this.times, this.isUsingFallback);
}
