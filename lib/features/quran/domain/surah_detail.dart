class SurahDetail {
  final String surahName;
  final String surahNameArabic;
  final String surahNameArabicLong;
  final String surahNameTranslation;
  final String revelationPlace;
  final int totalAyah;
  final int surahNo;
  final Map<String, dynamic> audio;
  final List<String> english;
  final List<String> arabic1;
  final List<String> arabic2;
  final List<String> bengali;
  final List<String>? uzbek;

  SurahDetail({
    required this.surahName,
    required this.surahNameArabic,
    required this.surahNameArabicLong,
    required this.surahNameTranslation,
    required this.revelationPlace,
    required this.totalAyah,
    required this.surahNo,
    required this.audio,
    required this.english,
    required this.arabic1,
    required this.arabic2,
    required this.bengali,
    this.uzbek,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    return SurahDetail(
      surahName: json['surahName'] ?? '',
      surahNameArabic: json['surahNameArabic'] ?? '',
      surahNameArabicLong: json['surahNameArabicLong'] ?? '',
      surahNameTranslation: json['surahNameTranslation'] ?? '',
      revelationPlace: json['revelationPlace'] ?? '',
      totalAyah: json['totalAyah'] ?? 0,
      surahNo: json['surahNo'] ?? 0,
      audio: json['audio'] ?? {},
      english: List<String>.from(json['english'] ?? []),
      arabic1: List<String>.from(json['arabic1'] ?? []),
      arabic2: List<String>.from(json['arabic2'] ?? []),
      bengali: List<String>.from(json['bengali'] ?? []),
      uzbek: json['uzbek'] != null ? List<String>.from(json['uzbek']) : null,
    );
  }
}
