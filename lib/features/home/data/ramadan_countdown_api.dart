import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../core/providers/models.dart';

class RamadanCountdownApi {
  static const String _baseUrl = 'https://ramadan.zakiego.com/api/countdown';

  static Future<RamadanCountdown> fetchCountdown({int? timezoneOffset}) async {
    // Get timezone offset if not provided
    final offset = timezoneOffset ?? DateTime.now().timeZoneOffset.inHours;
    final url = Uri.parse('$_baseUrl?timezoneOffset=$offset');

    // Try up to 3 times with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return RamadanCountdown.fromJson(data);
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        if (attempt == 3) {
          // Last attempt failed - return fallback with default Ramadan date
          final fallbackRamadanDate = DateTime(2026, 2, 18);
          final now = DateTime.now();
          final difference = fallbackRamadanDate.difference(now);
          
          return RamadanCountdown(
            ramadanStartDate: fallbackRamadanDate,
            currentDate: now,
            timezoneOffset: offset,
            countdown: {
              'days': difference.isNegative ? 0 : difference.inDays,
              'hours': difference.isNegative ? 0 : difference.inHours % 24,
              'minutes': difference.isNegative ? 0 : difference.inMinutes % 60,
              'seconds': difference.isNegative ? 0 : difference.inSeconds % 60,
            },
          );
        } else {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    // This should never be reached, but just in case
    final fallbackRamadanDate = DateTime(2026, 2, 18);
    final now = DateTime.now();
    final difference = fallbackRamadanDate.difference(now);
    
    return RamadanCountdown(
      ramadanStartDate: fallbackRamadanDate,
      currentDate: now,
      timezoneOffset: offset,
      countdown: {
        'days': difference.isNegative ? 0 : difference.inDays,
        'hours': difference.isNegative ? 0 : difference.inHours % 24,
        'minutes': difference.isNegative ? 0 : difference.inMinutes % 60,
        'seconds': difference.isNegative ? 0 : difference.inSeconds % 60,
      },
    );
  }
}
