import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../features/home/data/prayer_time_api.dart';

class AppContextProvider {
  static Future<String> generateAppContext() async {
    final prefs = await SharedPreferences.getInstance();
    final userStats = await _getUserPrayerStats(prefs);
    final appFeatures = _getAppFeatures();
    final userPreferences = await _getUserPreferences(prefs);
    final locationInfo = await _getLocationInfo();
    final currentTime = DateTime.now();

    return '''
=== NOOR ISLAMIC APP CONTEXT ===

📱 APP FEATURES AVAILABLE:
$appFeatures

👤 USER STATISTICS:
$userStats

🕐 CURRENT TIME: ${_formatDateTime(currentTime)}
📍 LOCATION INFO: $locationInfo

⚙️ USER PREFERENCES:
$userPreferences

🎯 PERSONALIZATION INSTRUCTIONS:
- Reference specific app features when relevant
- Provide personalized Islamic guidance based on user's prayer habits
- Suggest app features that can help with user's questions
- Use prayer statistics to give encouraging or motivational advice
- Consider time of day for relevant Islamic practices
- Adapt advice based on user's location and prayer times

This context should inform your Islamic guidance to be more helpful and personalized.
''';
  }

  static String _getAppFeatures() {
    return '''
• 🕌 Prayer Times - Accurate prayer times based on location with multiple calculation methods
• 📖 Quran - Complete Quran with translations and audio recitation
• 📚 Hadith - Collection of authentic Hadith from major books
• 🤲 Azkhar - Daily dhikr and supplications with counters
• 📿 Tasbih - Digital prayer beads for dhikr counting
• 🧭 Qibla - Accurate Qibla direction finder using compass
• 🤖 Islamic AI Assistant - Knowledgeable Islamic guidance (current feature)
• 🏠 Home Dashboard - Overview of daily Islamic activities
• ⚙️ More Settings - App customization and Islamic tools
''';
  }

  static Future<String> _getUserPrayerStats(SharedPreferences prefs) async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // Get today's prayer completions
    final fajrCompleted = prefs.getBool('prayer_fajr_$todayKey') ?? false;
    final dhuhrCompleted = prefs.getBool('prayer_dhuhr_$todayKey') ?? false;
    final asrCompleted = prefs.getBool('prayer_asr_$todayKey') ?? false;
    final maghribCompleted = prefs.getBool('prayer_maghrib_$todayKey') ?? false;
    final ishaCompleted = prefs.getBool('prayer_isha_$todayKey') ?? false;

    final todayCount = [fajrCompleted, dhuhrCompleted, asrCompleted, maghribCompleted, ishaCompleted]
        .where((completed) => completed).length;

    // Get weekly stats (last 7 days)
    int weeklyTotal = 0;
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      for (String prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        if (prefs.getBool('prayer_${prayer}_$key') ?? false) {
          weeklyTotal++;
        }
      }
    }

    // Get total prayers ever completed
    final totalPrayers = prefs.getInt('total_prayers_completed') ?? 0;
    final streak = prefs.getInt('prayer_streak') ?? 0;
    final lastPrayerTime = prefs.getString('last_prayer_time') ?? 'Never';

    return '''
Today's Prayers: $todayCount/5
• Fajr: ${fajrCompleted ? '✅' : '❌'}
• Dhuhr: ${dhuhrCompleted ? '✅' : '❌'}
• Asr: ${asrCompleted ? '✅' : '❌'}
• Maghrib: ${maghribCompleted ? '✅' : '❌'}
• Isha: ${ishaCompleted ? '✅' : '❌'}

Weekly Total: $weeklyTotal/35 prayers
Total Prayers Completed: $totalPrayers
Current Streak: $streak days
Last Prayer Logged: $lastPrayerTime

Prayer Completion Rate: ${totalPrayers > 0 ? ((weeklyTotal / 35) * 100).toStringAsFixed(1) : '0'}% this week
''';
  }

  static Future<String> _getUserPreferences(SharedPreferences prefs) async {
    final selectedMadhab = prefs.getString('selected_madhab') ?? 'Not set';
    final prayerReminders = prefs.getBool('prayer_reminders') ?? true;
    final arabicText = prefs.getBool('show_arabic') ?? true;
    final darkMode = prefs.getBool('dark_mode') ?? false;
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final lastAppUsage = prefs.getString('last_app_usage') ?? 'First time';

    return '''
• Madhab Preference: $selectedMadhab
• Prayer Reminders: ${prayerReminders ? 'Enabled' : 'Disabled'}
• Arabic Text Display: ${arabicText ? 'Enabled' : 'Disabled'}
• Dark Mode: ${darkMode ? 'Enabled' : 'Disabled'}
• Notifications: ${notificationsEnabled ? 'Enabled' : 'Disabled'}
• Last App Usage: $lastAppUsage
''';
  }

  static Future<String> _getLocationInfo() async {
    try {
      // Try to get current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission not granted (using Mecca as default)';
      }

      Position position = await Geolocator.getCurrentPosition();

      // Get today's prayer times for user's location
      final prayerTimes = await PrayerTimeApi.fetchPrayerTimes(
        lat: position.latitude,
        lon: position.longitude,
      );

      return '''
Latitude: ${position.latitude.toStringAsFixed(4)}
Longitude: ${position.longitude.toStringAsFixed(4)}

Today's Prayer Times:
• Fajr: ${prayerTimes['Fajr']}
• Dhuhr: ${prayerTimes['Dhuhr']}
• Asr: ${prayerTimes['Asr']}
• Maghrib: ${prayerTimes['Maghrib']}
• Isha: ${prayerTimes['Isha']}
''';
    } catch (e) {
      return 'Location unavailable (using default prayer times)';
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Methods to update prayer statistics
  static Future<void> markPrayerCompleted(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final prayerKey = 'prayer_${prayerName.toLowerCase()}_$todayKey';

    // Mark prayer as completed
    await prefs.setBool(prayerKey, true);

    // Update total count
    final totalPrayers = prefs.getInt('total_prayers_completed') ?? 0;
    await prefs.setInt('total_prayers_completed', totalPrayers + 1);

    // Update last prayer time
    await prefs.setString('last_prayer_time', _formatDateTime(today));

    // Calculate and update streak
    await _updatePrayerStreak(prefs);
  }

  static Future<void> _updatePrayerStreak(SharedPreferences prefs) async {
    final today = DateTime.now();
    int streak = 0;

    // Check consecutive days with at least one prayer
    for (int i = 0; i < 365; i++) { // Check up to a year
      final date = today.subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';

      bool hasAnyPrayer = false;
      for (String prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        if (prefs.getBool('prayer_${prayer}_$key') ?? false) {
          hasAnyPrayer = true;
          break;
        }
      }

      if (hasAnyPrayer) {
        streak++;
      } else {
        break;
      }
    }

    await prefs.setInt('prayer_streak', streak);
  }

  // Update app usage
  static Future<void> updateAppUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_app_usage', _formatDateTime(DateTime.now()));
  }
}
