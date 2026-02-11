import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/chapter.dart';

class ChaptersApi {
  static const String _apiKey =
      r'$2y$10$Mu5EDCnFeFJ5xvrPP9RZ5eDTYXoE5f1tTWqyfrQ3lnOW45IJjrEai';

  static Future<List<HadithChapter>> fetchChapters(String bookSlug) async {
    final String cacheKey = 'hadith_chapters_$bookSlug';
    final url = 'https://hadithapi.com/api/$bookSlug/chapters?apiKey=$_apiKey';

    // 1. Try Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Background refresh
        _refreshCacheInBackground(url, cacheKey, prefs);

        final data = json.decode(cached);
        return _parseChapters(data, bookSlug);
      }
    } catch (_) {}

    // 2. Try Local Asset
    try {
      final assetPath = 'assets/data/hadith_chapters/$bookSlug.json';
      final jsonString = await rootBundle.loadString(assetPath);
      if (jsonString.isNotEmpty) {
        final data = json.decode(jsonString);
        // Save to cache for next time logic consistency, though not strictly needed if asset exists
        // Background refresh to get latest dynamic data if any
        final prefs = await SharedPreferences.getInstance();
        _refreshCacheInBackground(url, cacheKey, prefs);

        return _parseChapters(data, bookSlug);
      }
    } catch (_) {
      // Asset might not exist for this book
    }

    // 3. Fetch Network
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, body);

        final data = json.decode(body);
        return _parseChapters(data, bookSlug);
      } else {
        throw Exception('Failed to load chapters: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Failed to load')) rethrow;

      // 3. Fallback to cache even if empty/stale check failed previously?
      // (Redundant if Step 1 covers it, but good for offline error handling)
      throw Exception(
        'Unable to connect to server. Please check your internet connection.',
      );
    }
  }

  static List<HadithChapter> _parseChapters(dynamic data, String bookSlug) {
    List<dynamic> chaptersList = [];
    if (data['chapters'] == null) {
      return [];
    } else if (data['chapters'] is List) {
      chaptersList = data['chapters'] as List<dynamic>;
    } else if (data['chapters'] is Map) {
      chaptersList = (data['chapters'] as Map).values.toList();
    }
    return chaptersList
        .map((c) => HadithChapter.fromJson(c, bookSlug))
        .toList();
  }

  static void _refreshCacheInBackground(
    String url,
    String cacheKey,
    SharedPreferences prefs,
  ) {
    Future(() async {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await prefs.setString(cacheKey, utf8.decode(response.bodyBytes));
        }
      } catch (_) {}
    });
  }
}
