import 'package:flutter/material.dart';
import '../domain/book.dart';
import '../domain/chapter.dart';
import '../data/chapters_api.dart';
import 'chapter_detail_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final HadithBook book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<List<HadithChapter>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = ChaptersApi.fetchChapters(widget.book.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.name)),
      body: FutureBuilder<List<HadithChapter>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chapters found'));
          }
          final chapters = snapshot.data!;
          return ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return ListTile(
                title: Text(chapter.english),
                subtitle: Text('Chapter ${chapter.chapterNumber}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterDetailScreen(
                      bookSlug: widget.book.slug,
                      chapter: chapter,
                    ),
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
