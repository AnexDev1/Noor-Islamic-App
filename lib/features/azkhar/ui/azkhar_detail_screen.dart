import 'package:flutter/material.dart';
import '../domain/azkhar_category.dart';
import '../domain/azkhar_item.dart';

class AzkharDetailScreen extends StatelessWidget {
  final AzkharCategory category;
  const AzkharDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name, textDirection: TextDirection.rtl)),
      body: ListView.builder(
        itemCount: category.items.length,
        itemBuilder: (context, index) {
          final item = category.items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.content, style: const TextStyle(fontSize: 20, fontFamily: 'Amiri'), textDirection: TextDirection.rtl),
                  const SizedBox(height: 8),
                  Text('التكرار: ${item.count}', style: const TextStyle(fontSize: 16, color: Colors.blueGrey), textDirection: TextDirection.rtl),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('الفضل: ${item.description}', style: const TextStyle(fontSize: 16, color: Colors.green), textDirection: TextDirection.rtl),
                  ],
                  if (item.reference.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('المصدر: ${item.reference}', style: const TextStyle(fontSize: 14, color: Colors.grey), textDirection: TextDirection.rtl),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
