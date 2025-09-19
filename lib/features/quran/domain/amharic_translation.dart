class AmharicTranslation {
  final int sura;
  final int aya;
  final String translation;
  final String? footnotes;

  AmharicTranslation({
    required this.sura,
    required this.aya,
    required this.translation,
    this.footnotes,
  });

  factory AmharicTranslation.fromJson(Map<String, dynamic> json) {
    return AmharicTranslation(
      sura: int.tryParse(json['sura'] ?? '0') ?? 0,
      aya: int.tryParse(json['aya'] ?? '0') ?? 0,
      translation: json['translation'] ?? '',
      footnotes: json['footnotes'],
    );
  }
}
