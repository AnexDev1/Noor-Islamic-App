import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../domain/quran_enc_translation.dart';

class QuranEncTranslationApi {
  static Future<List<QuranEncTranslation>> fetchSurahTranslation(
    String translationKey,
    int surahNo, {
    int retries = 2,
  }) async {
    final url =
        'https://quranenc.com/api/v1/translation/sura/$translationKey/$surahNo';

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List translations = data['result'] ?? [];
          return translations
              .map((e) => QuranEncTranslation.fromJson(e))
              .toList();
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        if (attempt == retries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Failed to load translation');
  }

  static Future<QuranEncTranslation> fetchAyahTranslation(
    String translationKey,
    int surahNo,
    int ayahNo, {
    int retries = 2,
  }) async {
    final url =
        'https://quranenc.com/api/v1/translation/aya/$translationKey/$surahNo/$ayahNo';
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return QuranEncTranslation.fromJson(data);
        } else {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        if (attempt == retries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Failed to load ayah translation');
  }
}
