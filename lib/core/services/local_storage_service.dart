import 'package:hive_flutter/hive_flutter.dart';

/// Centralized local storage service using Hive.
/// All feature data is stored in named boxes.
class LocalStorageService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _initialized = true;
  }

  // ── Box names ──
  static const String dhikrBox = 'dhikr_sessions';
  static const String quranStreakBox = 'quran_streak';
  static const String reflectionsBox = 'reflections';
  static const String ramadanHabitsBox = 'ramadan_habits';
  static const String noorWrapBox = 'noor_wrap';
  static const String settingsBox = 'feature_settings';

  static Future<Box> openBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    return await Hive.openBox(name);
  }

  /// Save a map value with a key.
  static Future<void> put(String boxName, String key, dynamic value) async {
    final box = await openBox(boxName);
    await box.put(key, value);
  }

  /// Get a value by key.
  static Future<dynamic> get(
    String boxName,
    String key, {
    dynamic defaultValue,
  }) async {
    final box = await openBox(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  /// Get all values in a box.
  static Future<Map<dynamic, dynamic>> getAll(String boxName) async {
    final box = await openBox(boxName);
    return box.toMap();
  }

  /// Delete a key.
  static Future<void> delete(String boxName, String key) async {
    final box = await openBox(boxName);
    await box.delete(key);
  }

  /// Clear all data in a box.
  static Future<void> clearBox(String boxName) async {
    final box = await openBox(boxName);
    await box.clear();
  }
}
