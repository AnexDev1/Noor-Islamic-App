import 'package:flutter/material.dart';
import '../data/quran_api.dart';
import '../domain/surah_info.dart';
import 'widgets/surah_list.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late Future<List<SurahInfo>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = QuranApi.fetchSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quran Chapters')),
      body: FutureBuilder<List<SurahInfo>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Surahs found'));
          }
          final surahs = snapshot.data!;
          return SurahList(surahs: surahs);
        },
      ),
    );
  }
}
