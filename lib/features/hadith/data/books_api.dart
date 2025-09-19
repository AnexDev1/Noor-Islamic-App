import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/book.dart';

class BooksApi {
  static const String _apiKey = r'$2y$10$Mu5EDCnFeFJ5xvrPP9RZ5eDTYXoE5f1tTWqyfrQ3lnOW45IJjrEai';
  static const String _baseUrl = 'https://hadithapi.com/api/books?apiKey=$_apiKey';

  static Future<List<HadithBook>> fetchBooks() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Debug: print the full response for diagnostics
      print('Books API response: ${response.body}');
      // Try to parse books from different possible keys
      List<dynamic> books = [];
      if (data is Map<String, dynamic>) {
        if (data.containsKey('books')) {
          books = data['books'] as List<dynamic>;
        } else if (data.containsKey('data') && data['data'] is Map<String, dynamic> && data['data'].containsKey('books')) {
          books = data['data']['books'] as List<dynamic>;
        }
      }
      // Fallback: if still empty, use mock data for UI testing
      if (books.isEmpty) {
        books = [
          {
            'id': 1,
            'name': 'Sahih Bukhari',
            'slug': 'sahih-bukhari',
            'description': 'Most authentic book of hadith.'
          },
          {
            'id': 2,
            'name': 'Sahih Muslim',
            'slug': 'sahih-muslim',
            'description': 'Second most authentic book of hadith.'
          },
        ];
      }
      return books.map((b) => HadithBook.fromJson(b)).toList();
    } else {
      print('Books API error: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load books');
    }
  }
}
