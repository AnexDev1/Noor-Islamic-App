import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/surah_info.dart';

class QuranApi {
  static Future<List<SurahInfo>> fetchSurahs() async {
    final response = await http.get(Uri.parse('https://quranapi.pages.dev/api/surah.json'));
    if (response.statusCode == 200) {
      final List surahList = json.decode(response.body);
      return surahList.map((e) => SurahInfo.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load surahs');
    }
  }
}

