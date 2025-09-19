import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/quran_enc_translation.dart';

class QuranEncTranslationApi {
  static Future<List<QuranEncTranslation>> fetchSurahTranslation(String translationKey, int surahNo) async {
    final url = 'https://quranenc.com/api/v1/translation/sura/$translationKey/$surahNo';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List translations = data['result'] ?? [];
      return translations.map((e) => QuranEncTranslation.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load translation');
    }
  }

  static Future<QuranEncTranslation> fetchAyahTranslation(String translationKey, int surahNo, int ayahNo) async {
    final url = 'https://quranenc.com/api/v1/translation/aya/$translationKey/$surahNo/$ayahNo';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return QuranEncTranslation.fromJson(data);
    } else {
      throw Exception('Failed to load ayah translation');
    }
  }
}
