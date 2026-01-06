import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import '../../features/home/data/prayer_time_api.dart';
import 'models.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// User Location Provider
class UserLocationNotifier extends StateNotifier<AsyncValue<UserLocation>> {
  UserLocationNotifier(this._prefs) : super(const AsyncValue.loading()) {
    _loadLocation();
  }

  final SharedPreferences _prefs;

  Future<void> _loadLocation() async {
    try {
      // Try to load cached location first
      final cachedLat = _prefs.getDouble('user_lat');
      final cachedLon = _prefs.getDouble('user_lon');
      final cachedCity = _prefs.getString('user_city');
      final cachedCountry = _prefs.getString('user_country');
      final cachedTimestamp = _prefs.getInt('location_timestamp');

      if (cachedLat != null &&
          cachedLon != null &&
          cachedCity != null &&
          cachedCountry != null) {
        final location = UserLocation(
          latitude: cachedLat,
          longitude: cachedLon,
          city: cachedCity,
          country: cachedCountry,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(
            cachedTimestamp ?? 0,
          ),
        );
        state = AsyncValue.data(location);
      }

      // Then try to get current location
      await getCurrentLocation();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Use Mecca as fallback
        final fallbackLocation = UserLocation(
          latitude: 21.4225,
          longitude: 39.8262,
          city: 'Mecca',
          country: 'Saudi Arabia',
          isUsingFallback: true,
          lastUpdated: DateTime.now(),
        );
        state = AsyncValue.data(fallbackLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      // Reverse geocode to get city and country
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final city = placemark?.locality ?? 'Unknown City';
      final country = placemark?.country ?? 'Unknown Country';

      final location = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        isUsingFallback: false,
        lastUpdated: DateTime.now(),
      );

      // Cache the location
      await _prefs.setDouble('user_lat', position.latitude);
      await _prefs.setDouble('user_lon', position.longitude);
      await _prefs.setString('user_city', city);
      await _prefs.setString('user_country', country);
      await _prefs.setInt(
        'location_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      state = AsyncValue.data(location);
    } catch (e) {
      // If we can't get location, use fallback but don't override existing cached location
      if (!state.hasValue) {
        final fallbackLocation = UserLocation(
          latitude: 21.4225,
          longitude: 39.8262,
          city: 'Mecca',
          country: 'Saudi Arabia',
          isUsingFallback: true,
          lastUpdated: DateTime.now(),
        );
        state = AsyncValue.data(fallbackLocation);
      }
    }
  }

  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    await getCurrentLocation();
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, AsyncValue<UserLocation>>((
      ref,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return UserLocationNotifier(prefs);
    });

// Prayer Times Provider
class PrayerTimesNotifier extends StateNotifier<AsyncValue<PrayerTimes>> {
  PrayerTimesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadPrayerTimes();
  }

  final Ref _ref;
  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  Future<void> _loadPrayerTimes() async {
    try {
      // Load cached prayer times first
      final cachedTimes = _prefs.getString('prayer_times');
      final cachedTimestamp = _prefs.getInt('prayer_times_timestamp');

      if (cachedTimes != null && cachedTimestamp != null) {
        final timesMap = Map<String, String>.from(json.decode(cachedTimes));
        final cachedLat = _prefs.getDouble('prayer_times_lat');
        final cachedLon = _prefs.getDouble('prayer_times_lon');
        final isUsingFallback =
            _prefs.getBool('prayer_times_fallback') ?? false;
        final isUsingApiFallback =
            _prefs.getBool('prayer_times_api_fallback') ?? false;

        final prayerTimes = PrayerTimes.fromMap(
          timesMap,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(cachedTimestamp),
          latitude: cachedLat,
          longitude: cachedLon,
          isUsingFallbackLocation: isUsingFallback,
          isUsingFallbackPrayerTimes: isUsingApiFallback,
        );

        state = AsyncValue.data(prayerTimes);

        // Check if we need to refresh (if it's a new day)
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        final now = DateTime.now();
        if (lastUpdate.day != now.day ||
            lastUpdate.month != now.month ||
            lastUpdate.year != now.year) {
          await refreshPrayerTimes();
        }
      } else {
        await refreshPrayerTimes();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshPrayerTimes() async {
    try {
      final locationAsync = _ref.read(userLocationProvider);
      if (!locationAsync.hasValue) {
        await _ref.read(userLocationProvider.notifier).getCurrentLocation();
      }

      final location = _ref.read(userLocationProvider).value;
      if (location == null) throw Exception('No location available');

      final result = await PrayerTimeApi.fetchPrayerTimes(
        lat: location.latitude,
        lon: location.longitude,
      );

      final prayerTimes = PrayerTimes.fromMap(
        result.times,
        lastUpdated: DateTime.now(),
        latitude: location.latitude,
        longitude: location.longitude,
        isUsingFallbackLocation: location.isUsingFallback,
        isUsingFallbackPrayerTimes: result.isUsingFallback,
      );

      // Cache the prayer times
      await _prefs.setString('prayer_times', json.encode(result.times));
      await _prefs.setInt(
        'prayer_times_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      await _prefs.setDouble('prayer_times_lat', location.latitude);
      await _prefs.setDouble('prayer_times_lon', location.longitude);
      await _prefs.setBool('prayer_times_fallback', location.isUsingFallback);
      await _prefs.setBool('prayer_times_api_fallback', result.isUsingFallback);

      state = AsyncValue.data(prayerTimes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final prayerTimesProvider =
    StateNotifierProvider<PrayerTimesNotifier, AsyncValue<PrayerTimes>>((ref) {
      return PrayerTimesNotifier(ref);
    });

// Prayer Status Provider (Today's Prayer Tracking)
class TodayPrayerStatusNotifier extends StateNotifier<PrayerStatus> {
  TodayPrayerStatusNotifier(this._prefs)
    : super(PrayerStatus.empty(DateTime.now())) {
    _loadTodayStatus();
  }

  final SharedPreferences _prefs;

  Future<void> _loadTodayStatus() async {
    final today = DateTime.now();
    final todayKey = _formatDate(today);

    final dailyPrayers = <String, bool>{
      'Fajr': _prefs.getBool('prayer_fajr_$todayKey') ?? false,
      'Dhuhr': _prefs.getBool('prayer_dhuhr_$todayKey') ?? false,
      'Asr': _prefs.getBool('prayer_asr_$todayKey') ?? false,
      'Maghrib': _prefs.getBool('prayer_maghrib_$todayKey') ?? false,
      'Isha': _prefs.getBool('prayer_isha_$todayKey') ?? false,
    };

    state = PrayerStatus(dailyPrayers: dailyPrayers, date: today);
  }

  Future<void> togglePrayer(String prayerName) async {
    final currentStatus = state.dailyPrayers[prayerName] ?? false;
    final newStatus = !currentStatus;
    final newPrayers = Map<String, bool>.from(state.dailyPrayers);
    newPrayers[prayerName] = newStatus;

    state = state.copyWith(dailyPrayers: newPrayers);

    // Save to preferences
    final today = state.date;
    final todayKey = _formatDate(today);
    await _prefs.setBool(
      'prayer_${prayerName.toLowerCase()}_$todayKey',
      newStatus,
    );

    // Update total prayers count
    if (newStatus) {
      final totalPrayers = _prefs.getInt('total_prayers_completed') ?? 0;
      await _prefs.setInt('total_prayers_completed', totalPrayers + 1);
      await _prefs.setString(
        'last_prayer_time',
        DateTime.now().toIso8601String(),
      );
    } else {
      final totalPrayers = _prefs.getInt('total_prayers_completed') ?? 0;
      await _prefs.setInt(
        'total_prayers_completed',
        (totalPrayers - 1).clamp(0, double.infinity).toInt(),
      );
    }

    // --- Professional Streak Logic ---
    await _updateStreak(today: today);
  }

  Future<void> _updateStreak({required DateTime today}) async {
    final todayKey = _formatDate(today);
    final lastIncrementDate = _prefs.getString('last_streak_increment_date');

    final allTodayCompleted = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].every(
      (p) => _prefs.getBool('prayer_${p.toLowerCase()}_$todayKey') ?? false,
    );

    if (allTodayCompleted) {
      // Only increment if we haven't already incremented for today
      if (lastIncrementDate != todayKey) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey = _formatDate(yesterday);
        final allYesterdayCompleted =
            ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].every(
              (p) =>
                  _prefs.getBool('prayer_${p.toLowerCase()}_$yesterdayKey') ??
                  false,
            );

        int currentStreak = _prefs.getInt('prayer_streak') ?? 0;
        int newStreak = allYesterdayCompleted ? currentStreak + 1 : 1;

        await _prefs.setInt('prayer_streak', newStreak);
        await _prefs.setString('last_streak_increment_date', todayKey);

        // Update longest streak
        final longestStreak = _prefs.getInt('longest_streak') ?? 0;
        if (newStreak > longestStreak) {
          await _prefs.setInt('longest_streak', newStreak);
        }
      }
    } else {
      // If the day is no longer complete, check if we need to reverse a previous increment
      if (lastIncrementDate == todayKey) {
        int currentStreak = _prefs.getInt('prayer_streak') ?? 0;
        int longestStreak = _prefs.getInt('longest_streak') ?? 0;

        // If the current streak was the longest, decrement longest streak as well
        if (currentStreak == longestStreak) {
          await _prefs.setInt(
            'longest_streak',
            (longestStreak - 1).clamp(0, 999999),
          );
        }

        await _prefs.setInt(
          'prayer_streak',
          (currentStreak - 1).clamp(0, 999999),
        );
        await _prefs.remove('last_streak_increment_date');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

final todayPrayerStatusProvider =
    StateNotifierProvider<TodayPrayerStatusNotifier, PrayerStatus>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return TodayPrayerStatusNotifier(prefs);
    });

// Prayer Statistics Provider
class PrayerStatsNotifier extends StateNotifier<PrayerStats> {
  PrayerStatsNotifier(this._prefs) : super(PrayerStats.empty()) {
    _loadStats();
  }

  final SharedPreferences _prefs;

  Future<void> _loadStats() async {
    final totalPrayers = _prefs.getInt('total_prayers_completed') ?? 0;
    final lastPrayerTime = _prefs.getString('last_prayer_time') ?? 'Never';

    // Calculate prayer counts
    final prayerCounts = <String, int>{
      'Fajr': _prefs.getInt('prayer_count_fajr') ?? 0,
      'Dhuhr': _prefs.getInt('prayer_count_dhuhr') ?? 0,
      'Asr': _prefs.getInt('prayer_count_asr') ?? 0,
      'Maghrib': _prefs.getInt('prayer_count_maghrib') ?? 0,
      'Isha': _prefs.getInt('prayer_count_isha') ?? 0,
    };

    // Use persisted streak value for display
    final persistedStreak = _prefs.getInt('prayer_streak') ?? 0;
    final longestStreak = _prefs.getInt('longest_streak') ?? persistedStreak;
    final weeklyCompletionRate = await _calculateWeeklyCompletionRate();
    final recentActivity = await _getRecentActivity();

    // Update longest streak if current is higher
    if (persistedStreak > longestStreak) {
      await _prefs.setInt('longest_streak', persistedStreak);
    }

    state = PrayerStats(
      totalPrayers: totalPrayers,
      currentStreak: persistedStreak,
      longestStreak: longestStreak > persistedStreak
          ? longestStreak
          : persistedStreak,
      prayerCounts: prayerCounts,
      weeklyCompletionRate: weeklyCompletionRate,
      lastPrayerTime: lastPrayerTime,
      recentActivity: recentActivity,
    );
  }

  Future<int> _calculateCurrentStreak() async {
    final today = DateTime.now();
    int streak = 0;
    bool missedDay = false;

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = _formatDate(date);

      int dailyCount = 0;
      for (String prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        if (_prefs.getBool('prayer_${prayer}_$dateKey') ?? false) {
          dailyCount++;
        }
      }

      if (dailyCount >= 5) {
        // All 5 prayers completed
        streak++;
      } else {
        // Only reset if a full day is missed
        missedDay = true;
        break;
      }
    }

    // Persist streak value
    await _prefs.setInt('prayer_streak', streak);
    return streak;
  }

  Future<double> _calculateWeeklyCompletionRate() async {
    final today = DateTime.now();
    int completedPrayers = 0;
    const totalPossiblePrayers = 35; // 7 days × 5 prayers

    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = _formatDate(date);

      for (String prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        if (_prefs.getBool('prayer_${prayer}_$dateKey') ?? false) {
          completedPrayers++;
        }
      }
    }

    return (completedPrayers / totalPossiblePrayers) * 100;
  }

  Future<List<PrayerStatus>> _getRecentActivity() async {
    final today = DateTime.now();
    List<PrayerStatus> activity = [];

    for (int i = 0; i < 30; i++) {
      // Last 30 days
      final date = today.subtract(Duration(days: i));
      final dateKey = _formatDate(date);

      final dailyPrayers = <String, bool>{
        'Fajr': _prefs.getBool('prayer_fajr_$dateKey') ?? false,
        'Dhuhr': _prefs.getBool('prayer_dhuhr_$dateKey') ?? false,
        'Asr': _prefs.getBool('prayer_asr_$dateKey') ?? false,
        'Maghrib': _prefs.getBool('prayer_maghrib_$dateKey') ?? false,
        'Isha': _prefs.getBool('prayer_isha_$dateKey') ?? false,
      };

      activity.add(PrayerStatus(dailyPrayers: dailyPrayers, date: date));
    }

    return activity;
  }

  Future<void> refreshStats() async {
    await _loadStats();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

final prayerStatsProvider =
    StateNotifierProvider<PrayerStatsNotifier, PrayerStats>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PrayerStatsNotifier(prefs);
    });

// User Preferences Provider
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(this._prefs) : super(UserPreferences.defaults) {
    _loadPreferences();
  }

  final SharedPreferences _prefs;

  Future<void> _loadPreferences() async {
    final selectedMadhab = _prefs.getString('selected_madhab') ?? 'Not set';
    final prayerReminders = _prefs.getBool('prayer_reminders') ?? true;
    final showArabic = _prefs.getBool('show_arabic') ?? true;
    final darkMode = _prefs.getBool('dark_mode') ?? false;
    final notificationsEnabled =
        _prefs.getBool('notifications_enabled') ?? true;
    final lastAppUsage = _prefs.getString('last_app_usage') ?? 'First time';

    state = UserPreferences(
      selectedMadhab: selectedMadhab,
      prayerReminders: prayerReminders,
      showArabic: showArabic,
      darkMode: darkMode,
      notificationsEnabled: notificationsEnabled,
      lastAppUsage: lastAppUsage,
    );
  }

  Future<void> updateMadhab(String madhab) async {
    state = state.copyWith(selectedMadhab: madhab);
    await _prefs.setString('selected_madhab', madhab);
  }

  Future<void> togglePrayerReminders() async {
    state = state.copyWith(prayerReminders: !state.prayerReminders);
    await _prefs.setBool('prayer_reminders', state.prayerReminders);
  }

  Future<void> toggleArabicText() async {
    state = state.copyWith(showArabic: !state.showArabic);
    await _prefs.setBool('show_arabic', state.showArabic);
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(darkMode: !state.darkMode);
    await _prefs.setBool('dark_mode', state.darkMode);
  }

  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    await _prefs.setBool('notifications_enabled', state.notificationsEnabled);
  }

  Future<void> updateLastAppUsage() async {
    final now = DateTime.now().toIso8601String();
    state = state.copyWith(lastAppUsage: now);
    await _prefs.setString('last_app_usage', now);
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return UserPreferencesNotifier(prefs);
    });

// Combined App Context Provider for AI
final appContextProvider = FutureProvider<String>((ref) async {
  final prayerTimes = ref.watch(prayerTimesProvider);
  final todayStatus = ref.watch(todayPrayerStatusProvider);
  final stats = ref.watch(prayerStatsProvider);
  final location = ref.watch(userLocationProvider);
  final preferences = ref.watch(userPreferencesProvider);

  return _generateAppContext(
    prayerTimes: prayerTimes.value,
    todayStatus: todayStatus,
    stats: stats,
    location: location.value,
    preferences: preferences,
  );
});

String _generateAppContext({
  PrayerTimes? prayerTimes,
  required PrayerStatus todayStatus,
  required PrayerStats stats,
  UserLocation? location,
  required UserPreferences preferences,
}) {
  final currentTime = DateTime.now();

  return '''
=== NOOR ISLAMIC APP CONTEXT ===

📱 APP FEATURES AVAILABLE:
• 🕌 Prayer Times - Accurate prayer times based on location with multiple calculation methods
• 📖 Quran - Complete Quran with translations and audio recitation
• 📚 Hadith - Collection of authentic Hadith from major books
• 🤲 Azkhar - Daily dhikr and supplications with counters
• 📿 Tasbih - Digital prayer beads for dhikr counting
• 🧭 Qibla - Accurate Qibla direction finder using compass
• 🤖 Islamic AI Assistant - Knowledgeable Islamic guidance (current feature)
• 🏠 Home Dashboard - Overview of daily Islamic activities
• ⚙️ More Settings - App customization and Islamic tools

👤 USER STATISTICS:
Today's Prayers: ${todayStatus.completedPrayers}/5
• Fajr: ${todayStatus.dailyPrayers['Fajr']! ? '✅' : '❌'}
• Dhuhr: ${todayStatus.dailyPrayers['Dhuhr']! ? '✅' : '❌'}
• Asr: ${todayStatus.dailyPrayers['Asr']! ? '✅' : '❌'}
• Maghrib: ${todayStatus.dailyPrayers['Maghrib']! ? '✅' : '❌'}
• Isha: ${todayStatus.dailyPrayers['Isha']! ? '✅' : '❌'}

Weekly Completion Rate: ${stats.weeklyCompletionRate.toStringAsFixed(1)}%
Total Prayers Completed: ${stats.totalPrayers}
Current Streak: ${stats.currentStreak} days
Longest Streak: ${stats.longestStreak} days
Last Prayer Logged: ${stats.lastPrayerTime}

🕐 CURRENT TIME: ${_formatDateTime(currentTime)}
📍 LOCATION INFO: ${location != null ? '${location.city}, ${location.country}' : 'Location unavailable'}

${prayerTimes != null ? '''
Today's Prayer Times:
• Fajr: ${prayerTimes.fajr}
• Dhuhr: ${prayerTimes.dhuhr}
• Asr: ${prayerTimes.asr}
• Maghrib: ${prayerTimes.maghrib}
• Isha: ${prayerTimes.isha}
''' : 'Prayer times unavailable'}

⚙️ USER PREFERENCES:
• Madhab Preference: ${preferences.selectedMadhab}
• Prayer Reminders: ${preferences.prayerReminders ? 'Enabled' : 'Disabled'}
• Arabic Text Display: ${preferences.showArabic ? 'Enabled' : 'Disabled'}
• Dark Mode: ${preferences.darkMode ? 'Enabled' : 'Disabled'}
• Notifications: ${preferences.notificationsEnabled ? 'Enabled' : 'Disabled'}
• Last App Usage: ${preferences.lastAppUsage}

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

String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}
