import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecitersApi {
  static const String _url = 'https://quranapi.pages.dev/api/reciters.json';
  static const String _cacheKey = 'reciters';

  static Future<Map<String, String>> fetchReciters() async {
    // Return cached data immediately if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Background refresh
        Future(() async {
          try {
            final uri = Uri.parse(_url);
            final response = await _retryHttpGet(uri, attempts: 3);
            if (response.statusCode == 200) {
              await prefs.setString(_cacheKey, utf8.decode(response.bodyBytes));
            }
          } catch (_) {}
        });

        final data = json.decode(cached) as Map<String, dynamic>;

        // Remove problematic reciters (missing audio/404)
        data.removeWhere((key, value) {
          final name = value.toString().toLowerCase();
          return name.contains('hani ar rifai') ||
              name.contains('naseer al qatami');
        });

        return data.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {}

    // No cache - fetch from network
    try {
      final uri = Uri.parse(_url);
      final response = await _retryHttpGet(uri, attempts: 3);
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = json.decode(body) as Map<String, dynamic>;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, body);
        } catch (_) {}

        // Remove problematic reciters
        data.removeWhere((key, value) {
          final name = value.toString().toLowerCase();
          return name.contains('hani ar rifai') ||
              name.contains('naseer al qatami');
        });

        return data.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {
      // swallow and try fallback
    }

    // Try cache fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final data = json.decode(cached) as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {}

    throw Exception(
      'Unable to load reciters. The service may be temporarily unavailable. Please check your internet connection and try again in a few minutes.',
    );
  }

  static Future<http.Response> _retryHttpGet(
    Uri uri, {
    int attempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final resp = await http
            .get(
              uri,
              headers: {
                'User-Agent': 'NoorApp/1.0.0 (Flutter; Android)',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 15));
        return resp;
      } catch (e) {
        if (attempt >= attempts) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }
}
