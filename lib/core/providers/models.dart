// Prayer data models
class PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final DateTime lastUpdated;
  final double? latitude;
  final double? longitude;
  final bool isUsingFallbackLocation;
  final bool isUsingFallbackPrayerTimes;

  const PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.lastUpdated,
    this.latitude,
    this.longitude,
    this.isUsingFallbackLocation = false,
    this.isUsingFallbackPrayerTimes = false,
  });

  Map<String, String> toMap() {
    return {
      'Fajr': fajr,
      'Dhuhr': dhuhr,
      'Asr': asr,
      'Maghrib': maghrib,
      'Isha': isha,
    };
  }

  PrayerTimes copyWith({
    String? fajr,
    String? dhuhr,
    String? asr,
    String? maghrib,
    String? isha,
    DateTime? lastUpdated,
    double? latitude,
    double? longitude,
    bool? isUsingFallbackLocation,
    bool? isUsingFallbackPrayerTimes,
  }) {
    return PrayerTimes(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isUsingFallbackLocation:
          isUsingFallbackLocation ?? this.isUsingFallbackLocation,
      isUsingFallbackPrayerTimes:
          isUsingFallbackPrayerTimes ?? this.isUsingFallbackPrayerTimes,
    );
  }

  static PrayerTimes fromMap(
    Map<String, String> map, {
    DateTime? lastUpdated,
    double? latitude,
    double? longitude,
    bool isUsingFallbackLocation = false,
    bool isUsingFallbackPrayerTimes = false,
  }) {
    return PrayerTimes(
      fajr: map['Fajr'] ?? '',
      dhuhr: map['Dhuhr'] ?? '',
      asr: map['Asr'] ?? '',
      maghrib: map['Maghrib'] ?? '',
      isha: map['Isha'] ?? '',
      lastUpdated: lastUpdated ?? DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      isUsingFallbackLocation: isUsingFallbackLocation,
      isUsingFallbackPrayerTimes: isUsingFallbackPrayerTimes,
    );
  }
}

class PrayerStatus {
  final Map<String, bool> dailyPrayers;
  final DateTime date;

  const PrayerStatus({required this.dailyPrayers, required this.date});

  PrayerStatus copyWith({Map<String, bool>? dailyPrayers, DateTime? date}) {
    return PrayerStatus(
      dailyPrayers: dailyPrayers ?? Map.from(this.dailyPrayers),
      date: date ?? this.date,
    );
  }

  int get completedPrayers =>
      dailyPrayers.values.where((completed) => completed).length;

  bool get isComplete => completedPrayers == 5;

  static PrayerStatus empty(DateTime date) {
    return PrayerStatus(
      dailyPrayers: {
        'Fajr': false,
        'Dhuhr': false,
        'Asr': false,
        'Maghrib': false,
        'Isha': false,
      },
      date: date,
    );
  }
}

class PrayerStats {
  final int totalPrayers;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> prayerCounts;
  final double weeklyCompletionRate;
  final String lastPrayerTime;
  final List<PrayerStatus> recentActivity;

  const PrayerStats({
    required this.totalPrayers,
    required this.currentStreak,
    required this.longestStreak,
    required this.prayerCounts,
    required this.weeklyCompletionRate,
    required this.lastPrayerTime,
    required this.recentActivity,
  });

  PrayerStats copyWith({
    int? totalPrayers,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? prayerCounts,
    double? weeklyCompletionRate,
    String? lastPrayerTime,
    List<PrayerStatus>? recentActivity,
  }) {
    return PrayerStats(
      totalPrayers: totalPrayers ?? this.totalPrayers,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      prayerCounts: prayerCounts ?? Map.from(this.prayerCounts),
      weeklyCompletionRate: weeklyCompletionRate ?? this.weeklyCompletionRate,
      lastPrayerTime: lastPrayerTime ?? this.lastPrayerTime,
      recentActivity: recentActivity ?? List.from(this.recentActivity),
    );
  }

  static PrayerStats empty() {
    return const PrayerStats(
      totalPrayers: 0,
      currentStreak: 0,
      longestStreak: 0,
      prayerCounts: {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0},
      weeklyCompletionRate: 0.0,
      lastPrayerTime: 'Never',
      recentActivity: [],
    );
  }

  Map<DateTime, int> get heatmapData {
    final Map<DateTime, int> data = {};
    for (final activity in recentActivity) {
      data[activity.date] = activity.completedPrayers;
    }
    return data;
  }
}

class UserLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final bool isUsingFallback;
  final DateTime lastUpdated;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.isUsingFallback = false,
    required this.lastUpdated,
  });

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    bool? isUsingFallback,
    DateTime? lastUpdated,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      isUsingFallback: isUsingFallback ?? this.isUsingFallback,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static final UserLocation mecca = UserLocation(
    latitude: 21.4225,
    longitude: 39.8262,
    city: 'Mecca',
    country: 'Saudi Arabia',
    isUsingFallback: true,
    lastUpdated: DateTime(2023, 10, 10), // This will be handled differently
  );
}

class UserPreferences {
  final String selectedMadhab;
  final bool prayerReminders;
  final bool showArabic;
  final bool darkMode;
  final bool notificationsEnabled;
  final String lastAppUsage;

  const UserPreferences({
    required this.selectedMadhab,
    required this.prayerReminders,
    required this.showArabic,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.lastAppUsage,
  });

  UserPreferences copyWith({
    String? selectedMadhab,
    bool? prayerReminders,
    bool? showArabic,
    bool? darkMode,
    bool? notificationsEnabled,
    String? lastAppUsage,
  }) {
    return UserPreferences(
      selectedMadhab: selectedMadhab ?? this.selectedMadhab,
      prayerReminders: prayerReminders ?? this.prayerReminders,
      showArabic: showArabic ?? this.showArabic,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastAppUsage: lastAppUsage ?? this.lastAppUsage,
    );
  }

  static const UserPreferences defaults = UserPreferences(
    selectedMadhab: 'Not set',
    prayerReminders: true,
    showArabic: true,
    darkMode: false,
    notificationsEnabled: true,
    lastAppUsage: 'First time',
  );
}
