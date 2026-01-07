import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/azkhar_category.dart';

class AzkharApi {
  static const String _mainUrl =
      'https://raw.githubusercontent.com/nawafalqari/ayah/main/src/data/adkar.json';
  static const String _cacheKey = 'azkhar_categories';

  static Future<List<AzkharCategory>> fetchCategories() async {
    // Return cached data immediately if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Background refresh
        Future(() async {
          try {
            final response = await http
                .get(Uri.parse(_mainUrl))
                .timeout(const Duration(seconds: 15));
            if (response.statusCode == 200) {
              await prefs.setString(_cacheKey, response.body);
            }
          } catch (_) {}
        });

        final Map<String, dynamic> data = json.decode(cached);
        return data.entries
            .map(
              (entry) =>
                  AzkharCategory.fromJson(entry.key, entry.value as List),
            )
            .toList();
      }
    } catch (_) {}

    final response = await http
        .get(Uri.parse(_mainUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, response.body);
      } catch (_) {}
      return data.entries
          .map(
            (entry) => AzkharCategory.fromJson(entry.key, entry.value as List),
          )
          .toList();
    } else {
      // try cache as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_cacheKey);
        if (cached != null && cached.isNotEmpty) {
          final Map<String, dynamic> data = json.decode(cached);
          return data.entries
              .map(
                (entry) =>
                    AzkharCategory.fromJson(entry.key, entry.value as List),
              )
              .toList();
        }
      } catch (_) {}
      throw Exception(
        'Unable to load Azkhar categories. The service may be temporarily unavailable. Please check your internet connection and try again in a few minutes.',
      );
    }
  }
}
