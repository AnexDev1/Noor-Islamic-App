import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/book.dart';

class BooksApi {
  // Use static data for instant loading and reliability
  static Future<List<HadithBook>> fetchBooks() async {
    // Simulate a tiny delay purely for UI smoothness (optional)
    await Future.delayed(const Duration(milliseconds: 100));

    final List<Map<String, dynamic>> booksData = [
      {
        "id": 1,
        "bookName": "Sahih Bukhari",
        "writerName": "Imam Bukhari",
        "writerDeath": "256 H",
        "bookSlug": "sahih-bukhari",
        "hadiths_count": 7563,
        "chapters_count": 99,
      },
      {
        "id": 2,
        "bookName": "Sahih Muslim",
        "writerName": "Imam Muslim",
        "writerDeath": "261 H",
        "bookSlug": "sahih-muslim",
        "hadiths_count": 7563, // Approx
        "chapters_count": 56,
      },
      {
        "id": 3,
        "bookName": "Jami' Al-Tirmidhi",
        "writerName": "Imam Tirmidhi",
        "writerDeath": "279 H",
        "bookSlug": "al-tirmidhi",
        "hadiths_count": 3956,
        "chapters_count": 46,
      },
      {
        "id": 4,
        "bookName": "Sunan Abu Dawood",
        "writerName": "Imam Abu Dawood",
        "writerDeath": "275 H",
        "bookSlug": "abu-dawood",
        "hadiths_count": 5274,
        "chapters_count": 43,
      },
      {
        "id": 5,
        "bookName": "Sunan Ibn Majah",
        "writerName": "Imam Ibn Majah",
        "writerDeath": "273 H",
        "bookSlug": "ibn-e-majah",
        "hadiths_count": 4341,
        "chapters_count": 37,
      },
      {
        "id": 6,
        "bookName": "Sunan An-Nasa'i",
        "writerName": "Imam An-Nasa'i",
        "writerDeath": "303 H",
        "bookSlug": "sunan-nasai",
        "hadiths_count": 5758,
        "chapters_count": 52,
      },
      {
        "id": 7,
        "bookName": "Mishkat Al-Masabih",
        "writerName": "Al-Tabrizi",
        "writerDeath": "741 H",
        "bookSlug": "mishkat",
        "hadiths_count": 6294,
        "chapters_count": 29,
      },
      {
        "id": 8,
        "bookName": "Musnad Ahmad",
        "writerName": "Imam Ahmad",
        "writerDeath": "241 H",
        "bookSlug": "musnad-ahmad",
        "hadiths_count": 28199,
        "chapters_count": 0,
      },
    ];

    return booksData.map((b) => HadithBook.fromJson(b)).toList();
  }
}
