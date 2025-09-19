import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerTimeApi {
  static const String _apiKey = 'vjjIVhO2Ym1fVc4GAePdqwKQnKisJZQLegI9ySxIcWodv4eL';
  static const String _baseUrl = 'https://islamicapi.com/api/v1/prayer-time/';

  // Default location: Mecca
  static const double _defaultLat = 21.4225;
  static const double _defaultLon = 39.8262;
  static const int _defaultMethod = 3; // Muslim World League
  static const int _defaultSchool = 1; // Shafi

  static Future<Map<String, String>> fetchPrayerTimes({
    double? lat,
    double? lon,
    int? method,
    int? school,
  }) async {
    final url = Uri.parse(
      '$_baseUrl?lat=${lat ?? _defaultLat}&lon=${lon ?? _defaultLon}&method=${method ?? _defaultMethod}&school=${school ?? _defaultSchool}&api_key=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final times = data['data']['times'] as Map<String, dynamic>;
      // Only keep the main prayers
      return {
        'Fajr': times['Fajr'] ?? '',
        'Dhuhr': times['Dhuhr'] ?? '',
        'Asr': times['Asr'] ?? '',
        'Maghrib': times['Maghrib'] ?? '',
        'Isha': times['Isha'] ?? '',
      };
    } else {
      throw Exception('Unable to fetch prayer times');
    }
  }
}

