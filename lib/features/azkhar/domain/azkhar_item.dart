class AzkharItem {
  final String category;
  final int count;
  final String description;
  final String reference;
  final String content;

  AzkharItem({
    required this.category,
    required this.count,
    required this.description,
    required this.reference,
    required this.content,
  });

  factory AzkharItem.fromJson(Map<String, dynamic> json) {
    return AzkharItem(
      category: json['category'] ?? '',
      count: int.tryParse(json['count']?.toString() ?? '1') ?? 1,
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
      content: json['content'] ?? '',
    );
  }
}
