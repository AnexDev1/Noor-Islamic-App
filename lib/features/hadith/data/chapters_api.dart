import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/chapter.dart';

class ChaptersApi {
  static const String _apiKey = r'$2y$10$Mu5EDCnFeFJ5xvrPP9RZ5eDTYXoE5f1tTWqyfrQ3lnOW45IJjrEai';

  static Future<List<HadithChapter>> fetchChapters(String bookSlug) async {
    final url = 'https://hadithapi.com/api/$bookSlug/chapters?apiKey=$_apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Chapters API response: ${response.body}');
      print('Chapters type: ${data['chapters']?.runtimeType.toString() ?? 'null'}');
      List<dynamic> chaptersList = [];
      if (data['chapters'] == null) {
        print('Chapters key is missing or null');
      } else if (data['chapters'] is List) {
        chaptersList = data['chapters'] as List<dynamic>;
      } else if (data['chapters'] is Map) {
        chaptersList = (data['chapters'] as Map).values.toList();
      } else {
        print('Chapters key is not a List or Map, got: ' + data['chapters'].runtimeType.toString());
      }
      print('Parsed chapters count: ${chaptersList.length}');
      return chaptersList.map((c) => HadithChapter.fromJson(c, bookSlug)).toList();
    } else {
      print('Chapters API error: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load chapters');
    }
  }
}
