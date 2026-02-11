import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/surah_info.dart';

class QuranApi {
  static const String _cacheKey = 'cached_surahs';

  static Future<List<SurahInfo>> fetchSurahs({int retries = 3}) async {
    const url = 'https://quranapi.pages.dev/api/surah.json';

    // 1. Try to load from SharedPreferences (fastest, user-specific updates)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Background refresh from network
        _refreshCacheInBackground(url, prefs);

        final List surahList = json.decode(cached);
        return surahList.map((e) => SurahInfo.fromJson(e)).toList();
      }
    } catch (_) {}

    // 2. Try to load from local Asset Bundle (fast, offline-ready, consistent)
    try {
      final jsonString = await rootBundle.loadString('assets/data/surahs.json');
      // Background refresh from network
      SharedPreferences.getInstance().then(
        (prefs) => _refreshCacheInBackground(url, prefs),
      );

      final List surahList = json.decode(jsonString);
      return surahList.map((e) => SurahInfo.fromJson(e)).toList();
    } catch (_) {
      // Asset not found or error reading, proceed to network
    }

    // 3. Fallback to Network (slowest, but necessary if asset missing)
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final body = utf8.decode(response.bodyBytes);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, body);

          final List surahList = json.decode(body);
          return surahList.map((e) => SurahInfo.fromJson(e)).toList();
        }
      } catch (e) {
        if (attempt == retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    throw Exception('Unable to load surahs. Please check your connection.');
  }

  static void _refreshCacheInBackground(String url, SharedPreferences prefs) {
    Future(() async {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          await prefs.setString(_cacheKey, utf8.decode(response.bodyBytes));
        }
      } catch (_) {}
    });
  }
}
