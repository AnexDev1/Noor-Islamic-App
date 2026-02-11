import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/azkhar_category.dart';

class AzkharApi {
  static const String _mainUrl =
      'https://raw.githubusercontent.com/nawafalqari/ayah/main/src/data/adkar.json';
  static const String _cacheKey = 'azkhar_categories';

  static Future<List<AzkharCategory>> fetchCategories() async {
    // 1. Try to load from SharedPreferences (fastest, user-specific updates)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Background refresh from network
        _refreshCacheInBackground();

        final Map<String, dynamic> data = json.decode(cached);
        return data.entries
            .map(
              (entry) =>
                  AzkharCategory.fromJson(entry.key, entry.value as List),
            )
            .toList();
      }
    } catch (_) {}

    // 2. Try to load from local Asset Bundle (fast, offline-ready, consistent)
    try {
      final jsonString = await rootBundle.loadString('assets/data/adkar.json');
      // Background refresh from network
      _refreshCacheInBackground();

      final Map<String, dynamic> data = json.decode(jsonString);
      return data.entries
          .map(
            (entry) => AzkharCategory.fromJson(entry.key, entry.value as List),
          )
          .toList();
    } catch (_) {
      // Asset not found or error reading, proceed to network
    }

    // 3. Fallback to Network (slowest)
    try {
      final response = await http
          .get(Uri.parse(_mainUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(body);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, body);
        } catch (_) {}
        return data.entries
            .map(
              (entry) =>
                  AzkharCategory.fromJson(entry.key, entry.value as List),
            )
            .toList();
      }
    } catch (_) {}

    throw Exception(
      'Unable to load Azkhar categories. Please check your internet connection.',
    );
  }

  static void _refreshCacheInBackground() {
    Future(() async {
      try {
        final response = await http
            .get(Uri.parse(_mainUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, utf8.decode(response.bodyBytes));
        }
      } catch (_) {}
    });
  }
}
