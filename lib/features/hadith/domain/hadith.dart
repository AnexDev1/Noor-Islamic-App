class Hadith {
  final int id;
  final String bookSlug;
  final int chapterNumber;
  final int hadithNumber;
  final String? arabic;
  final String? english;
  final String? urdu;
  final String? status;

  Hadith({
    required this.id,
    required this.bookSlug,
    required this.chapterNumber,
    required this.hadithNumber,
    this.arabic,
    this.english,
    this.urdu,
    this.status,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }
    return Hadith(
      id: parseInt(json['id']),
      bookSlug: parseString(json['book']),
      chapterNumber: parseInt(json['chapter']),
      hadithNumber: parseInt(json['hadithNumber']),
      arabic: parseString(json['hadithArabic']),
      english: parseString(json['hadithEnglish']),
      urdu: parseString(json['hadithUrdu']),
      status: parseString(json['status']),
    );
  }
}
