import 'package:flutter/material.dart';
import '../../domain/surah_info.dart';
import '../surah_detail_screen.dart';

class SurahList extends StatelessWidget {
  final List<SurahInfo> surahs;
  const SurahList({super.key, required this.surahs});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return ListTile(
          title: Text(surah.surahName),
          subtitle: Text(surah.surahNameArabic, style: const TextStyle(fontFamily: 'Amiri')),
          trailing: Text('Ayahs: ${surah.totalAyah}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SurahDetailScreen(
                  surahNo: index + 1,
                  surahName: surah.surahName,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
