class HadithChapter {
  final int id;
  final String bookSlug;
  final int chapterNumber;
  final String english;
  final String urdu;
  final String arabic;

  HadithChapter({
    required this.id,
    required this.bookSlug,
    required this.chapterNumber,
    required this.english,
    required this.urdu,
    required this.arabic,
  });

  factory HadithChapter.fromJson(Map<String, dynamic> json, String bookSlug) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    return HadithChapter(
      id: parseInt(json['id']),
      bookSlug: bookSlug,
      chapterNumber: parseInt(json['chapterNumber']),
      english: json['chapterEnglish'] ?? '',
      urdu: json['chapterUrdu'] ?? '',
      arabic: json['chapterArabic'] ?? '',
    );
  }
}
