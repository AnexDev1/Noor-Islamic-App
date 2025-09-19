import 'dart:convert';
import 'package:http/http.dart' as http;

class AudioApi {
  static Future<Map<String, dynamic>> fetchAyahAudio(int surahNo, int ayahNo) async {
    final url = 'https://quranapi.pages.dev/api/audio/$surahNo/$ayahNo.json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load ayah audio');
    }
  }

  static Future<Map<String, dynamic>> fetchSurahAudio(int surahNo) async {
    final url = 'https://quranapi.pages.dev/api/audio/$surahNo.json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load surah audio');
    }
  }
}

