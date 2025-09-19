import 'package:flutter/material.dart';
import '../domain/chapter.dart';
import '../domain/hadith.dart';
import '../data/hadiths_api.dart';
import 'hadith_detail_screen.dart';

class ChapterDetailScreen extends StatefulWidget {
  final String bookSlug;
  final HadithChapter chapter;
  const ChapterDetailScreen({super.key, required this.bookSlug, required this.chapter});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  late Future<List<Hadith>> _hadithsFuture;

  @override
  void initState() {
    super.initState();
    _hadithsFuture = HadithsApi.fetchHadiths(
      bookSlug: widget.bookSlug,
      chapterNumber: widget.chapter.chapterNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chapter.english)),
      body: FutureBuilder<List<Hadith>>(
        future: _hadithsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hadiths found'));
          }
          final hadiths = snapshot.data!;
          return ListView.builder(
            itemCount: hadiths.length,
            itemBuilder: (context, index) {
              final hadith = hadiths[index];
              return ListTile(
                title: Text((hadith.english ?? '').isNotEmpty ? hadith.english! : (hadith.arabic ?? '').isNotEmpty ? hadith.arabic! : 'Hadith ${hadith.hadithNumber}'),
                subtitle: Text('Hadith #${hadith.hadithNumber}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HadithDetailScreen(hadith: hadith),
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
