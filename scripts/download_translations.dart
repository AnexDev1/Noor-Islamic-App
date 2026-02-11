import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

const translations = ['amharic_zain', 'oromo_ababor', 'english_rwwad'];

Future<void> main() async {
  print('Starting Translation Downloads...');

  for (final key in translations) {
    print('Processing translation: $key');
    final dir = Directory('assets/data/translations/$key');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (int i = 1; i <= 114; i++) {
      final file = File('${dir.path}/$i.json');
      if (await file.exists()) {
        continue;
      }

      print('Downloading $key Surah $i...');
      try {
        // URL: https://quranenc.com/api/v1/translation/sura/$translationKey/$surahNo
        final uri = Uri.parse(
          'https://quranenc.com/api/v1/translation/sura/$key/$i',
        );
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          print('Saved $key Surah $i');
          await Future.delayed(const Duration(milliseconds: 100)); // be nice
        } else {
          print('Failed to download $key Surah $i: ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading $key Surah $i: $e');
      }
    }
  }
  print('Translation Downloads Complete.');
}
