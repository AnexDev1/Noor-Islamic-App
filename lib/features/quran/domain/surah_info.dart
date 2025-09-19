class SurahInfo {
  final String surahName;
  final String surahNameArabic;
  final String surahNameTranslation;
  final String revelationPlace;
  final int totalAyah;

  SurahInfo({
    required this.surahName,
    required this.surahNameArabic,
    required this.surahNameTranslation,
    required this.revelationPlace,
    required this.totalAyah,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) {
    return SurahInfo(
      surahName: json['surahName'] ?? '',
      surahNameArabic: json['surahNameArabic'] ?? '',
      surahNameTranslation: json['surahNameTranslation'] ?? '',
      revelationPlace: json['revelationPlace'] ?? '',
      totalAyah: json['totalAyah'] ?? 0,
    );
  }
}

