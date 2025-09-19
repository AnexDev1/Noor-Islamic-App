import 'azkhar_item.dart';

class AzkharCategory {
  final String name;
  final List<AzkharItem> items;

  AzkharCategory({
    required this.name,
    required this.items,
  });

  factory AzkharCategory.fromJson(String name, List<dynamic> itemsJson) {
    final items = itemsJson
        .map((item) => AzkharItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return AzkharCategory(
      name: name,
      items: items,
    );
  }
}
