import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Starting Quran Surah Download...');

  final dir = Directory('assets/data/quran');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  // 1 to 114 Surahs
  for (int i = 1; i <= 114; i++) {
    final file = File('${dir.path}/$i.json');
    if (await file.exists()) {
      // print('Skipping Surah $i (already exists)');
      continue;
    }

    print('Downloading Surah $i...');
    try {
      // API: https://quranapi.pages.dev/api/$i.json
      final uri = Uri.parse('https://quranapi.pages.dev/api/$i.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('Saved Surah $i');
        // Small delay to be polite
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        print('Failed to download Surah $i: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading Surah $i: $e');
    }
  }
  print('Quran Download complete.');
}
