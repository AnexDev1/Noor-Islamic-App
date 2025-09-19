import 'package:flutter/material.dart';
import '../data/azkhar_api.dart';
import '../domain/azkhar_category.dart';
import 'azkhar_detail_screen.dart';

class AzkharHomeScreen extends StatefulWidget {
  const AzkharHomeScreen({super.key});

  @override
  State<AzkharHomeScreen> createState() => _AzkharHomeScreenState();
}

class _AzkharHomeScreenState extends State<AzkharHomeScreen> {
  late Future<List<AzkharCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = AzkharApi.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      body: FutureBuilder<List<AzkharCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل الأذكار'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد أذكار'));
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name, textDirection: TextDirection.rtl),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AzkharDetailScreen(category: category),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
