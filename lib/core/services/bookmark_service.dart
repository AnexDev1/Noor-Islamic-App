import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BookmarkType { quran, hadith, azkhar, video }

class BookmarkItem {
  final String id;
  final String title;
  final String subtitle;
  final BookmarkType type;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const BookmarkItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.metadata,
    required this.timestamp,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      type: _bookmarkTypeFromString(json['type'] as String?),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? <String, dynamic>{},
      ),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': _bookmarkTypeToString(type),
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class BookmarkService {
  BookmarkService._();

  static final BookmarkService instance = BookmarkService._();
  static const String _storageKey = 'bookmarks_v1';

  final ValueNotifier<List<BookmarkItem>> bookmarks =
      ValueNotifier<List<BookmarkItem>>(<BookmarkItem>[]);

  bool _isLoaded = false;

  Future<void> initialize() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_isLoaded) {
      return;
    }
    await _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedItems = prefs.getStringList(_storageKey) ?? <String>[];
    final items =
        encodedItems
            .map((entry) {
              try {
                final decoded = jsonDecode(entry);
                if (decoded is Map<String, dynamic>) {
                  return BookmarkItem.fromJson(decoded);
                }
                if (decoded is Map) {
                  return BookmarkItem.fromJson(
                    Map<String, dynamic>.from(decoded),
                  );
                }
              } catch (_) {
                return null;
              }
              return null;
            })
            .whereType<BookmarkItem>()
            .toList()
          ..sort((left, right) => right.timestamp.compareTo(left.timestamp));

    bookmarks.value = items;
    _isLoaded = true;
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedItems = bookmarks.value
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(_storageKey, encodedItems);
  }

  Future<void> addBookmark(BookmarkItem item) async {
    await _ensureLoaded();
    final updatedItems = <BookmarkItem>[
      item,
      ...bookmarks.value.where(
        (existing) => existing.id != item.id || existing.type != item.type,
      ),
    ];
    bookmarks.value = updatedItems;
    await _saveBookmarks();
  }

  Future<void> removeBookmark(String id, BookmarkType type) async {
    await _ensureLoaded();
    bookmarks.value = bookmarks.value
        .where((item) => item.id != id || item.type != type)
        .toList();
    await _saveBookmarks();
  }

  Future<void> clearBookmarks() async {
    await _ensureLoaded();
    bookmarks.value = <BookmarkItem>[];
    await _saveBookmarks();
  }

  bool isBookmarked(String id, BookmarkType type) {
    return bookmarks.value.any((item) => item.id == id && item.type == type);
  }
}

BookmarkType _bookmarkTypeFromString(String? value) {
  switch (value) {
    case 'hadith':
      return BookmarkType.hadith;
    case 'azkhar':
      return BookmarkType.azkhar;
    case 'video':
      return BookmarkType.video;
    case 'quran':
    default:
      return BookmarkType.quran;
  }
}

String _bookmarkTypeToString(BookmarkType type) {
  switch (type) {
    case BookmarkType.quran:
      return 'quran';
    case BookmarkType.hadith:
      return 'hadith';
    case BookmarkType.azkhar:
      return 'azkhar';
    case BookmarkType.video:
      return 'video';
  }
}
