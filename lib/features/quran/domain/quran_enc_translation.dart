class QuranEncTranslation {
  final int sura;
  final int aya;
  final String translation;
  final String? footnotes;
  final String? arabicText;

  QuranEncTranslation({
    required this.sura,
    required this.aya,
    required this.translation,
    this.footnotes,
    this.arabicText,
  });

  factory QuranEncTranslation.fromJson(Map<String, dynamic> json) {
    return QuranEncTranslation(
      sura: int.tryParse(json['sura'] ?? '0') ?? 0,
      aya: int.tryParse(json['aya'] ?? '0') ?? 0,
      translation: json['translation'] ?? '',
      footnotes: json['footnotes'],
      arabicText: json['arabic_text'],
    );
  }
}

