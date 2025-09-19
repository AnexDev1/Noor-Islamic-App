class AppConstants {
  // App Info
  static const String appName = 'Noor';
  static const String appVersion = '1.0.0';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Grid Settings
  static const int homeGridColumns = 3; // Increased columns for compact grid
  static const double homeGridSpacing = 8.0; // Reduced spacing for compact grid

  // Carousel Settings
  static const Duration carouselAutoPlayDuration = Duration(seconds: 4);
  static const double carouselHeight = 200.0;

  // Islamic Constants
  static const List<String> islamicGreetings = [
    'Assalamu Alaikum',
    'Barakallahu feeki',
    'May Allah bless you',
    'Peace be upon you'
  ];

  // Feature Names
  static const String tasbihFeature = 'Tasbih';
  static const String hadithFeature = 'Hadith';
  static const String duaFeature = 'Dua';
  static const String quranFeature = 'Quran';
  static const String wallpaperFeature = 'Wallpaper';
  static const String donateFeature = 'Donate';
}
