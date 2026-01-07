import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/hadith.dart';

class HadithsApi {
  static const String _apiKey =
      r'$2y$10$Mu5EDCnFeFJ5xvrPP9RZ5eDTYXoE5f1tTWqyfrQ3lnOW45IJjrEai';

  static String _cacheKeyFor(Map<String, String> params) {
    // Ensure deterministic key order by sorting keys and URL-encoding values
    final sortedKeys = params.keys.toList()..sort();
    final key = sortedKeys
        .map((k) => '${k}=${Uri.encodeComponent(params[k] ?? '')}')
        .join('&');
    return 'hadiths_$key';
  }

  static Future<List<Hadith>> fetchHadiths({
    String? bookSlug,
    int? chapterNumber,
    String? hadithEnglish,
    String? hadithArabic,
    String? hadithUrdu,
    int? hadithNumber,
    String? status,
    int paginate = 25,
  }) async {
    final params = <String, String>{
      'apiKey': _apiKey,
      'paginate': paginate.toString(),
    };
    if (bookSlug != null) params['book'] = bookSlug;
    if (chapterNumber != null) params['chapter'] = chapterNumber.toString();
    if (hadithEnglish != null) params['hadithEnglish'] = hadithEnglish;
    if (hadithArabic != null) params['hadithArabic'] = hadithArabic;
    if (hadithUrdu != null) params['hadithUrdu'] = hadithUrdu;
    if (hadithNumber != null) params['hadithNumber'] = hadithNumber.toString();
    if (status != null) params['status'] = status;

    final cacheKey = _cacheKeyFor(params);

    // Return cached data immediately if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyKey =
          'hadiths_${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      String? cached = prefs.getString(cacheKey);
      if (cached == null || cached.isEmpty) {
        // try legacy key for backward compatibility
        cached = prefs.getString(legacyKey);
        if (cached != null && cached.isNotEmpty) {
          // migrate to new sorted key
          try {
            await prefs.setString(cacheKey, cached);
          } catch (_) {}
        }
      }
      if (cached != null && cached.isNotEmpty) {
        // Background refresh
        Future(() async {
          try {
            final uri = Uri.https('hadithapi.com', '/api/hadiths', params);
            final response = await http
                .get(uri)
                .timeout(const Duration(seconds: 15));
            if (response.statusCode == 200) {
              await prefs.setString(cacheKey, response.body);
            }
          } catch (_) {}
        });

        final data = json.decode(cached);
        var hadithsRaw = data['hadiths'];
        List<dynamic> hadithsList = [];
        if (hadithsRaw is Map && hadithsRaw['data'] is List) {
          hadithsList = hadithsRaw['data'] as List;
        } else if (hadithsRaw is List) {
          hadithsList = hadithsRaw;
        }
        return hadithsList.map((h) => Hadith.fromJson(h)).toList();
      }
    } catch (_) {}

    // No cache - fetch from network with retry and timeout
    final uri = Uri.https('hadithapi.com', '/api/hadiths', params);
    try {
      final response = await _retryHttpGet(uri, attempts: 3);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache the response
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, response.body);
        } catch (_) {}

        var hadithsRaw = data['hadiths'];
        List<dynamic> hadithsList = [];
        if (hadithsRaw is Map && hadithsRaw['data'] is List) {
          hadithsList = hadithsRaw['data'] as List;
        } else if (hadithsRaw is List) {
          hadithsList = hadithsRaw;
        }
        return hadithsList.map((h) => Hadith.fromJson(h)).toList();
      }
    } catch (_) {
      // swallow network errors here — we'll try cache fallback below
    }

    // Try cache as fallback (also try legacy key for backward compatibility)
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyKey =
          'hadiths_${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      String? cached = prefs.getString(cacheKey);
      if (cached == null || cached.isEmpty) {
        cached = prefs.getString(legacyKey);
        if (cached != null && cached.isNotEmpty) {
          // migrate to new sorted key
          try {
            await prefs.setString(cacheKey, cached);
          } catch (_) {}
        }
      }
      if (cached != null && cached.isNotEmpty) {
        final data = json.decode(cached);
        var hadithsRaw = data['hadiths'];
        List<dynamic> hadithsList = [];
        if (hadithsRaw is Map && hadithsRaw['data'] is List) {
          hadithsList = hadithsRaw['data'] as List;
        } else if (hadithsRaw is List) {
          hadithsList = hadithsRaw;
        }
        return hadithsList.map((h) => Hadith.fromJson(h)).toList();
      }
    } catch (_) {}

    // No cache and network failed — provide sanitized error
    throw Exception(
      'Unable to load hadiths. The service may be temporarily unavailable. Please check your internet connection and try again in a few minutes.',
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
        final resp = await http.get(uri).timeout(const Duration(seconds: 15));
        return resp;
      } catch (e) {
        if (attempt >= attempts) rethrow;
        // exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }
}
