import 'package:flutter/material.dart';
import '../domain/hadith.dart';

class HadithDetailScreen extends StatelessWidget {
  final Hadith hadith;
  const HadithDetailScreen({super.key, required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hadith #${hadith.hadithNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              (hadith.arabic ?? ''),
              style: const TextStyle(fontSize: 22, fontFamily: 'Amiri'),
              textAlign: TextAlign.right,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                (hadith.english ?? ''),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                (hadith.urdu ?? ''),
                style: const TextStyle(fontSize: 18, fontFamily: 'Scheherazade New'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Status: ${(hadith.status ?? '')}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
