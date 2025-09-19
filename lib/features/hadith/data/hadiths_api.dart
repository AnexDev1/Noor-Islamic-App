import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/hadith.dart';

class HadithsApi {
  static const String _apiKey = r'$2y$10$Mu5EDCnFeFJ5xvrPP9RZ5eDTYXoE5f1tTWqyfrQ3lnOW45IJjrEai';

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
    final uri = Uri.https('hadithapi.com', '/api/hadiths', params);
    final response = await http.get(uri);
    print('Hadiths API response: \\${response.body}'); // Debug print
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      var hadithsRaw = data['hadiths'];
      List<dynamic> hadithsList = [];
      if (hadithsRaw is Map && hadithsRaw['data'] is List) {
        hadithsList = hadithsRaw['data'] as List;
      } else if (hadithsRaw is List) {
        hadithsList = hadithsRaw;
      }
      return hadithsList.map((h) => Hadith.fromJson(h)).toList();
    } else {
      throw Exception('Failed to load hadiths');
    }
  }
}
