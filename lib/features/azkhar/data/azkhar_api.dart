import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/azkhar_category.dart';

class AzkharApi {
  static const String _mainUrl = 'https://raw.githubusercontent.com/nawafalqari/ayah/main/src/data/adkar.json';

  static Future<List<AzkharCategory>> fetchCategories() async {
    final response = await http.get(Uri.parse(_mainUrl));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.entries.map((entry) => AzkharCategory.fromJson(entry.key, entry.value as List)).toList();
    } else {
      throw Exception('Failed to load Azkhar categories');
    }
  }
}
