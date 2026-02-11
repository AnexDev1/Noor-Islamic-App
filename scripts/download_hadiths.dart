import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

// Configuration
const String apiKey =
    r'$2y$10$Mu5EDCnFeFJ5xvrPP9RZ5eDTYXoE5f1tTWqyfrQ3lnOW45IJjrEai';
const books = [
  {'slug': 'sahih-bukhari', 'chapters': 99},
  {'slug': 'sahih-muslim', 'chapters': 56},
  {'slug': 'al-tirmidhi', 'chapters': 46},
  {'slug': 'abu-dawood', 'chapters': 43},
  {'slug': 'ibn-e-majah', 'chapters': 37},
  {'slug': 'sunan-nasai', 'chapters': 52},
  {'slug': 'mishkat', 'chapters': 29},
  // Musnad Ahmad (ID 8) returns 404 on API/Check or has 0 chapters in config.
  // skipping for now or user can uncomment if fixed.
  // {'slug': 'musnad-ahmad', 'chapters': 0},
];

Future<void> main() async {
  print('Starting Hadith Assets Download...');

  for (final book in books) {
    final slug = book['slug'] as String;
    final chapters = book['chapters'] as int;
    final dir = Directory('assets/data/hadiths/$slug');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    print('Processing $slug ($chapters chapters)...');

    // For loop normally 1..chapters
    for (int i = 1; i <= chapters; i++) {
      final file = File('${dir.path}/$i.json');
      if (await file.exists()) {
        // print('Skipping $slug Chapter $i (already exists)');
        continue;
      }

      print('Downloading $slug Chapter $i...');
      try {
        final uri = Uri.https('hadithapi.com', '/api/hadiths', {
          'apiKey': apiKey,
          'book': slug,
          'chapter': i.toString(),
          'paginate': '10000', // Ensure we get EVERYTHING in one file
        });

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          // Basic validation to ensure we didn't just get an empty "success" with no data
          if (response.body.contains('"data":[]')) {
            print('Warning: $slug Chapter $i returned empty data.');
          }
          await file.writeAsBytes(response.bodyBytes);
          print('Saved $slug Chapter $i');
          // Sleep to avoid rate limits - slight increase for stability
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          print('Failed to download $slug Chapter $i: ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading $slug Chapter $i: $e');
      }
    }
  }
  print('Download complete.');
}
