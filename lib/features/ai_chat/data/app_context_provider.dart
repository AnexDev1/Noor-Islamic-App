import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/models.dart';
import '../../home/data/prayer_time_api.dart';

class AppContextProvider {
  // Enhanced app context generation with comprehensive user data
  static Future<String> generateAppContextFromProviders(WidgetRef ref) async {
    try {
      // Get all provider states
      final prayerTimesAsync = ref.read(prayerTimesProvider);
      final todayStatus = ref.read(todayPrayerStatusProvider);
      final stats = ref.read(prayerStatsProvider);
      final locationAsync = ref.read(userLocationProvider);
      final preferences = ref.read(userPreferencesProvider);

      // Get current location and prayer times
      final locationInfo = await _getDetailedLocationInfo();
      final prayerTimeInfo = await _getPrayerTimeInfo(locationAsync);

      return _generateEnhancedAppContext(
        prayerTimes: prayerTimesAsync.value,
        todayStatus: todayStatus,
        stats: stats,
        location: locationAsync.value,
        preferences: preferences,
        detailedLocation: locationInfo,
        prayerTimeDetails: prayerTimeInfo,
      );
    } catch (e) {
      return _generateFallbackContext();
    }
  }

  // Get detailed location information using geocoding
  static Future<Map<String, dynamic>> _getDetailedLocationInfo() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return {
          'city': 'Mecca',
          'country': 'Saudi Arabia',
          'coordinates': '21.4225, 39.8262',
          'timezone': 'Asia/Riyadh',
          'isUsingFallback': true,
          'accuracy': 'Fallback Location'
        };
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      // Get detailed address information
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      return {
        'city': placemark?.locality ?? 'Unknown City',
        'country': placemark?.country ?? 'Unknown Country',
        'state': placemark?.administrativeArea ?? '',
        'postalCode': placemark?.postalCode ?? '',
        'street': placemark?.street ?? '',
        'coordinates': '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'altitude': '${position.altitude.toStringAsFixed(1)}m',
        'accuracy': '±${position.accuracy.toStringAsFixed(1)}m',
        'isUsingFallback': false,
        'timestamp': DateTime.now().toIso8601String()
      };
    } catch (e) {
      return {
        'city': 'Location unavailable',
        'country': 'Unknown',
        'error': e.toString(),
        'isUsingFallback': true,
        'accuracy': 'Error getting location'
      };
    }
  }

  // Get comprehensive prayer time information
  static Future<Map<String, dynamic>> _getPrayerTimeInfo(AsyncValue<UserLocation> locationAsync) async {
    try {
      if (!locationAsync.hasValue) {
        return {'error': 'Location not available'};
      }

      final location = locationAsync.value!;
      final prayerTimes = await PrayerTimeApi.fetchPrayerTimes(
        lat: location.latitude,
        lon: location.longitude,
      );

      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Determine next prayer
      String nextPrayer = _getNextPrayer(prayerTimes, currentTime);

      return {
        'times': prayerTimes,
        'location': '${location.city}, ${location.country}',
        'coordinates': '${location.latitude}, ${location.longitude}',
        'currentTime': currentTime,
        'nextPrayer': nextPrayer,
        'isUsingFallback': location.isUsingFallback,
        'lastUpdated': location.lastUpdated.toIso8601String(),
      };
    } catch (e) {
      return {'error': 'Could not fetch prayer times: ${e.toString()}'};
    }
  }

  // Determine the next prayer based on current time
  static String _getNextPrayer(Map<String, String> prayerTimes, String currentTime) {
    final now = _timeToMinutes(currentTime);
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    for (String prayer in prayers) {
      final prayerTime = _timeToMinutes(prayerTimes[prayer] ?? '00:00');
      if (now < prayerTime) {
        return prayer;
      }
    }
    return 'Fajr (tomorrow)'; // If past Isha, next is Fajr
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return int.tryParse(parts[0]) ?? 0 * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  // Generate comprehensive app context with all user data
  static String _generateEnhancedAppContext({
    PrayerTimes? prayerTimes,
    required PrayerStatus todayStatus,
    required PrayerStats stats,
    UserLocation? location,
    required UserPreferences preferences,
    required Map<String, dynamic> detailedLocation,
    required Map<String, dynamic> prayerTimeDetails,
  }) {
    final currentTime = DateTime.now();

    return '''
=== NOOR ISLAMIC APP - COMPREHENSIVE USER CONTEXT ===

📱 APP FEATURES & CAPABILITIES:
• 🕌 Prayer Times - Location-based accurate prayer times with multiple calculation methods
• 📖 Quran - Complete Quran with translations, audio recitation, and bookmarks
• 📚 Hadith - Authentic Hadith collection from major books (Bukhari, Muslim, etc.)
• 🤲 Azkhar - Daily dhikr and supplications with counters and reminders
• 📿 Tasbih - Digital prayer beads for dhikr counting with different formulas
• 🧭 Qibla - Accurate Qibla direction finder using compass and GPS
• 🤖 Islamic AI Assistant - Personalized Islamic guidance (YOU - current feature)
• 🏠 Home Dashboard - Comprehensive overview of daily Islamic activities
• ⚙️ Settings - Complete app customization and Islamic calculation preferences
• 📊 Prayer Statistics - Detailed tracking, streaks, and progress analytics

🕐 CURRENT TIME & DATE: ${_formatDateTime(currentTime)}

📍 USER LOCATION (DETAILED):
${detailedLocation['isUsingFallback'] ? '⚠️ Using Fallback Location:' : '📍 Current Location:'}
• City: ${detailedLocation['city']}
• Country: ${detailedLocation['country']}
${detailedLocation['state'] != '' ? '• State/Region: ${detailedLocation['state']}' : ''}
• Coordinates: ${detailedLocation['coordinates']}
${!detailedLocation['isUsingFallback'] ? '• Altitude: ${detailedLocation['altitude']}' : ''}
• Location Accuracy: ${detailedLocation['accuracy']}
${detailedLocation['street'] != '' ? '• Street: ${detailedLocation['street']}' : ''}

🕌 PRAYER TIMES & STATUS:
${prayerTimeDetails['error'] != null ? 'Error: ${prayerTimeDetails['error']}' : '''
📅 Today's Prayer Schedule (${prayerTimeDetails['location']}):
• Fajr: ${prayerTimeDetails['times']['Fajr']} ${todayStatus.dailyPrayers['Fajr']! ? '✅ COMPLETED' : '❌ PENDING'}
• Dhuhr: ${prayerTimeDetails['times']['Dhuhr']} ${todayStatus.dailyPrayers['Dhuhr']! ? '✅ COMPLETED' : '❌ PENDING'}
• Asr: ${prayerTimeDetails['times']['Asr']} ${todayStatus.dailyPrayers['Asr']! ? '✅ COMPLETED' : '❌ PENDING'}
• Maghrib: ${prayerTimeDetails['times']['Maghrib']} ${todayStatus.dailyPrayers['Maghrib']! ? '✅ COMPLETED' : '❌ PENDING'}
• Isha: ${prayerTimeDetails['times']['Isha']} ${todayStatus.dailyPrayers['Isha']! ? '✅ COMPLETED' : '❌ PENDING'}

⏰ Current Time: ${prayerTimeDetails['currentTime']}
⏭️ Next Prayer: ${prayerTimeDetails['nextPrayer']}
📍 Prayer Location: ${prayerTimeDetails['location']}
'''}

📊 COMPREHENSIVE PRAYER STATISTICS:
📈 Today's Progress: ${todayStatus.completedPrayers}/5 prayers (${(todayStatus.completedPrayers / 5 * 100).toStringAsFixed(1)}%)
${todayStatus.completedPrayers == 5 ? '🎉 ALHAMDULILLAH! All prayers completed today!' :
  todayStatus.completedPrayers == 0 ? '🔔 No prayers logged today - start your spiritual journey!' :
  '⚡ ${5 - todayStatus.completedPrayers} prayers remaining today'}

🔥 Current Streak: ${stats.currentStreak} days
🏆 Longest Streak: ${stats.longestStreak} days
📅 Weekly Completion: ${stats.weeklyCompletionRate.toStringAsFixed(1)}% (${(stats.weeklyCompletionRate * 0.35).toStringAsFixed(0)}/35 prayers)
📈 Total Prayers Completed: ${stats.totalPrayers}
🕐 Last Prayer Logged: ${stats.lastPrayerTime}

📊 Prayer Breakdown (Individual Counts):
• Fajr: ${stats.prayerCounts['Fajr']} prayers
• Dhuhr: ${stats.prayerCounts['Dhuhr']} prayers
• Asr: ${stats.prayerCounts['Asr']} prayers
• Maghrib: ${stats.prayerCounts['Maghrib']} prayers
• Isha: ${stats.prayerCounts['Isha']} prayers

⚙️ USER PREFERENCES & CONFIGURATION:
• 📚 Selected Madhab: ${preferences.selectedMadhab}
• 🔔 Prayer Reminders: ${preferences.prayerReminders ? 'ENABLED' : 'DISABLED'}
• 🔤 Arabic Text Display: ${preferences.showArabic ? 'ENABLED' : 'DISABLED'}
• 🌙 Dark Mode: ${preferences.darkMode ? 'ENABLED (Dark Theme)' : 'DISABLED (Light Theme)'}
• 📱 App Notifications: ${preferences.notificationsEnabled ? 'ENABLED' : 'DISABLED'}
• 📅 Last App Usage: ${_formatLastUsage(preferences.lastAppUsage)}

🎯 AI ASSISTANT CAPABILITIES & PERSONALIZATION:
Based on the user's data, you can provide:

📊 STATISTICS QUERIES: When user asks about their progress, streaks, or prayer habits
📍 LOCATION SERVICES: Current location, prayer times for their area, Qibla direction
🕐 TIME-AWARE GUIDANCE: Contextual advice based on current prayer time and completion status
📈 PROGRESS TRACKING: Motivational insights based on their streaks and completion rates
⚙️ APP GUIDANCE: Help with app features, settings, and Islamic calculation methods
🕌 PERSONALIZED ISLAMIC ADVICE: Tailored to their madhab preference and prayer patterns

RESPONSE GUIDELINES:
- Use specific statistics when discussing progress or achievements
- Reference their exact location and prayer times when relevant
- Acknowledge their current streak and provide encouragement
- Suggest app features that align with their preferences and usage patterns
- Consider their madhab preference when giving Islamic guidance
- Be aware of their current prayer completion status for contextual advice
- Use their location for relevant Islamic guidance (Qibla, local Islamic events, etc.)

This comprehensive context enables you to provide highly personalized Islamic guidance and app assistance.
''';
  }

  // Fallback context when providers are unavailable
  static String _generateFallbackContext() {
    return '''
=== NOOR ISLAMIC APP - BASIC CONTEXT ===

📱 I'm your Islamic AI assistant in the Noor app. While I couldn't access all your data at the moment, I can still help you with:

🕌 Islamic guidance and questions about faith
📖 Quran verses and interpretations
📚 Hadith and Islamic teachings
🤲 Prayer guidance and Islamic practices
🧭 General Islamic advice and support

Please let me know how I can assist you with your Islamic journey today!
''';
  }

  static String _formatDateTime(DateTime dateTime) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];

    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String _formatLastUsage(String lastUsage) {
    if (lastUsage == 'First time') return 'First time user';

    try {
      final DateTime lastUsed = DateTime.parse(lastUsage);
      final Duration difference = DateTime.now().difference(lastUsed);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return lastUsage;
    }
  }

  // Legacy methods - kept for backward compatibility
  static Future<String> generateAppContext() async {
    throw UnimplementedError('Use generateAppContextFromProviders with WidgetRef instead');
  }

  static Future<String> getUserPrayerStats() async {
    throw UnimplementedError('Use prayerStatsProvider instead');
  }

  static Future<void> markPrayerCompleted(String prayerName) async {
    throw UnimplementedError('Use todayPrayerStatusProvider.notifier.togglePrayer() instead');
  }

  static Future<void> updateAppUsage() async {
    throw UnimplementedError('Use userPreferencesProvider.notifier.updateLastAppUsage() instead');
  }
}
