import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/surah_detail.dart';

class SurahApi {
  static const String _detailCachePrefix = 'surah_detail_';

  static Future<SurahDetail> fetchSurahDetail(
    int surahNo, {
    int retries = 3,
  }) async {
    final url = 'https://quranapi.pages.dev/api/$surahNo.json';

    // 1. Try to load from Assets (Fastest & Guaranteed Offline)
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/quran/$surahNo.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      return SurahDetail.fromJson(data);
    } catch (_) {
      // If asset likely doesn't exist or error, proceed to Cache/Network
    }

    // 2. If cached detail exists (fallback from previous validation)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_detailCachePrefix$surahNo');
      if (cached != null && cached.isNotEmpty) {
        // Background update
        Future(() async {
          try {
            final response = await http
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 10));
            if (response.statusCode == 200) {
              await prefs.setString(
                '$_detailCachePrefix$surahNo',
                response.body,
              );
            }
          } catch (_) {}
        });

        final Map<String, dynamic> data = json.decode(cached);
        return SurahDetail.fromJson(data);
      }
    } catch (_) {
      // ignore cache read errors
    }

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          // Cache surah detail for offline fallback
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('$_detailCachePrefix$surahNo', response.body);

          return SurahDetail.fromJson(data);
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        if (attempt == retries) {
          // Try to load cached detail as last resort
          try {
            final prefs = await SharedPreferences.getInstance();
            final cached = prefs.getString('$_detailCachePrefix$surahNo');
            if (cached != null && cached.isNotEmpty) {
              final Map<String, dynamic> data = json.decode(cached);
              return SurahDetail.fromJson(data);
            }
          } catch (_) {}

          rethrow;
        }

        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Failed to load surah detail');
  }
}
