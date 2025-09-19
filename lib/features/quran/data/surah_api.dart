import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/surah_detail.dart';

class SurahApi {
  static Future<SurahDetail> fetchSurahDetail(int surahNo) async {
    final response = await http.get(Uri.parse('https://quranapi.pages.dev/api/$surahNo.json'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return SurahDetail.fromJson(data);
    } else {
      throw Exception('Failed to load surah detail');
    }
  }
}

