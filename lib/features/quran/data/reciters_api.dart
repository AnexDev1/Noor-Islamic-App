import 'dart:convert';
import 'package:http/http.dart' as http;

class RecitersApi {
  static Future<Map<String, String>> fetchReciters() async {
    final url = 'https://quranapi.pages.dev/api/reciters.json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value.toString()));
    } else {
      throw Exception('Failed to load reciters');
    }
  }
}

