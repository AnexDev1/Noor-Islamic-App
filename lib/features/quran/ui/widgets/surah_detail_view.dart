import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/audio_api.dart';
import '../../domain/surah_detail.dart';
import '../../domain/quran_enc_translation.dart';

class SurahDetailView extends StatefulWidget {
  final SurahDetail surahDetail;
  final List<QuranEncTranslation> translations;
  final String reciterId;
  const SurahDetailView({super.key, required this.surahDetail, required this.translations, required this.reciterId});

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  Map<int, String> _ayahAudioUrls = {};
  int? _playingAyahIndex;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchAllAyahAudio();
  }

  @override
  void didUpdateWidget(covariant SurahDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reciterId != widget.reciterId || oldWidget.surahDetail.surahNo != widget.surahDetail.surahNo) {
      _fetchAllAyahAudio();
      _audioPlayer.stop();
      setState(() {
        _playingAyahIndex = null;
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchAllAyahAudio() async {
    final ayahAudioUrls = <int, String>{};
    for (int i = 0; i < widget.surahDetail.totalAyah; i++) {
      final ayahNo = i + 1;
      try {
        final audioMap = await AudioApi.fetchAyahAudio(widget.surahDetail.surahNo, ayahNo);
        if (audioMap.containsKey(widget.reciterId)) {
          ayahAudioUrls[i] = audioMap[widget.reciterId]['url'] ?? '';
        }
      } catch (_) {
        ayahAudioUrls[i] = '';
      }
    }
    setState(() {
      _ayahAudioUrls = ayahAudioUrls;
    });
  }

  Future<void> _onPlayPause(int index) async {
    final url = _ayahAudioUrls[index];
    if (url == null || url.isEmpty) return;
    if (_playingAyahIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
        _playingAyahIndex = null;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      setState(() {
        _playingAyahIndex = index;
        _isPlaying = true;
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _playingAyahIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.surahDetail.surahNameArabicLong,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.surahDetail.surahNameTranslation,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Revelation: ${widget.surahDetail.revelationPlace} | Ayahs: ${widget.surahDetail.totalAyah}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.surahDetail.totalAyah, (i) {
          final translation = widget.translations.length > i ? widget.translations[i].translation : '';
          final arabic = widget.translations.length > i && widget.translations[i].arabicText != null
              ? widget.translations[i].arabicText!
              : (widget.surahDetail.arabic1.length > i ? widget.surahDetail.arabic1[i] : '');
          final audioUrl = _ayahAudioUrls[i] ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arabic,
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 22),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  if (translation.isNotEmpty)
                    Text(
                      translation,
                      style: const TextStyle(fontSize: 16, color: Colors.brown),
                    ),
                  if (audioUrl.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_playingAyahIndex == i && _isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () => _onPlayPause(i),
                        ),
                        const Text('Audio'),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
