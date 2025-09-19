import 'package:flutter/material.dart';
import '../data/books_api.dart';
import '../domain/book.dart';
import 'book_detail_screen.dart';

class HadithHomeScreen extends StatefulWidget {
  const HadithHomeScreen({super.key});

  @override
  State<HadithHomeScreen> createState() => _HadithHomeScreenState();
}

class _HadithHomeScreenState extends State<HadithHomeScreen> {
  late Future<List<HadithBook>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = BooksApi.fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hadith Books')),
      body: FutureBuilder<List<HadithBook>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No books found'));
          }
          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.name),
                subtitle: Text('Slug: ${book.slug}\nAuthor: ${book.writer ?? ''}'),
                trailing: Text('Chapters: ${book.chaptersCount ?? ''}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(book: book),
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
