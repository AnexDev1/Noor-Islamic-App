import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/surah_info.dart';

class QuranApi {
  static const String _cacheKey = 'cached_surahs';

  static Future<List<SurahInfo>> fetchSurahs({int retries = 3}) async {
    const url = 'https://quranapi.pages.dev/api/surah.json';

    // Try to load cached data first for fast UX
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Kick off a background refresh to update the cache when possible
        Future(() async {
          try {
            final response = await http
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 15));
            if (response.statusCode == 200) {
              await prefs.setString(_cacheKey, response.body);
            }
          } catch (_) {
            // ignore background refresh errors
          }
        });

        final List surahList = json.decode(cached);
        return surahList.map((e) => SurahInfo.fromJson(e)).toList();
      }
    } catch (_) {
      // ignore cache read errors and fall back to network
    }

    // No cache - fetch from network with retries
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, response.body);

          final List surahList = json.decode(response.body);
          return surahList.map((e) => SurahInfo.fromJson(e)).toList();
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        if (attempt == retries) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final cached = prefs.getString(_cacheKey);
            if (cached != null && cached.isNotEmpty) {
              final List surahList = json.decode(cached);
              return surahList.map((e) => SurahInfo.fromJson(e)).toList();
            }
          } catch (_) {}

          throw Exception(
            'Unable to load surahs. The service may be temporarily unavailable. Please check your internet connection and try again in a few minutes.',
          );
        }

        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    throw Exception(
      'Unable to load surahs. The service may be temporarily unavailable. Please check your internet connection and try again in a few minutes.',
    );
  }
}
