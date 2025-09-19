import 'package:flutter/material.dart';
import '../data/amharic_translation_api.dart';
import '../data/surah_api.dart';
import '../data/reciters_api.dart';
import '../domain/amharic_translation.dart';
import '../domain/quran_enc_translation.dart';
import '../domain/surah_detail.dart';
import 'widgets/surah_detail_view.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNo;
  final String surahName;
  const SurahDetailScreen({super.key, required this.surahNo, required this.surahName});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<SurahDetail> _surahDetailFuture;
  late Future<List<QuranEncTranslation>> _translationFuture;
  late Future<Map<String, String>> _recitersFuture;
  String _selectedTranslationKey = 'amharic_zain';
  String _selectedReciterId = '1';
  Map<String, String> _reciters = {};

  final Map<String, String> _translationOptions = {
    'amharic_zain': 'Amharic',
    'oromo_ababor': 'Oromo',
    'english_rwwad': 'English',
    // Add more translation keys and labels here
  };

  @override
  void initState() {
    super.initState();
    _surahDetailFuture = SurahApi.fetchSurahDetail(widget.surahNo);
    _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(_selectedTranslationKey, widget.surahNo);
    _recitersFuture = RecitersApi.fetchReciters();
    _recitersFuture.then((reciters) {
      setState(() {
        _reciters = reciters;
        if (_reciters.isNotEmpty && !_reciters.containsKey(_selectedReciterId)) {
          _selectedReciterId = _reciters.keys.first;
        }
      });
    });
  }

  void _onTranslationChanged(String? key) {
    if (key != null && key != _selectedTranslationKey) {
      setState(() {
        _selectedTranslationKey = key;
        _translationFuture = QuranEncTranslationApi.fetchSurahTranslation(_selectedTranslationKey, widget.surahNo);
      });
    }
  }

  void _onReciterChanged(String? id) {
    if (id != null && id != _selectedReciterId) {
      setState(() {
        _selectedReciterId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.surahName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTranslationKey,
              decoration: const InputDecoration(labelText: 'Translation Language'),
              items: _translationOptions.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: _onTranslationChanged,
            ),
          ),
          FutureBuilder<Map<String, String>>(
            future: _recitersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const SizedBox();
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }
              final reciters = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedReciterId,
                  decoration: const InputDecoration(labelText: 'Reciter'),
                  items: reciters.entries
                      .map((e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _onReciterChanged,
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<SurahDetail>(
              future: _surahDetailFuture,
              builder: (context, surahSnapshot) {
                if (surahSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (surahSnapshot.hasError) {
                  return Center(child: Text('Error: ${surahSnapshot.error}'));
                } else if (!surahSnapshot.hasData) {
                  return const Center(child: Text('No data found'));
                }
                return FutureBuilder<List<QuranEncTranslation>>(
                  future: _translationFuture,
                  builder: (context, translationSnapshot) {
                    if (translationSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (translationSnapshot.hasError) {
                      return Center(child: Text('Error: ${translationSnapshot.error}'));
                    } else if (!translationSnapshot.hasData) {
                      return const Center(child: Text('No translation found'));
                    }
                    return SurahDetailView(
                      surahDetail: surahSnapshot.data!,
                      translations: translationSnapshot.data!,
                      reciterId: _selectedReciterId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
