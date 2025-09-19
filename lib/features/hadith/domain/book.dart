class HadithBook {
  final int id;
  final String name;
  final String slug;
  final String? writer;
  final String? writerDeath;
  final int? hadithsCount;
  final int? chaptersCount;

  HadithBook({
    required this.id,
    required this.name,
    required this.slug,
    this.writer,
    this.writerDeath,
    this.hadithsCount,
    this.chaptersCount,
  });

  factory HadithBook.fromJson(Map<String, dynamic> json) {
    return HadithBook(
      id: json['id'] ?? 0,
      name: json['bookName'] ?? '',
      slug: json['bookSlug'] ?? '',
      writer: json['writerName'] ?? '',
      writerDeath: json['writerDeath'] ?? '',
      hadithsCount: int.tryParse(json['hadiths_count']?.toString() ?? ''),
      chaptersCount: int.tryParse(json['chapters_count']?.toString() ?? ''),
    );
  }
}
