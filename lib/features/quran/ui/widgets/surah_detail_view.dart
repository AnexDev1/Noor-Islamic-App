import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/surah_detail.dart';
import '../../domain/quran_enc_translation.dart';

class SurahDetailView extends StatefulWidget {
  final SurahDetail surahDetail;
  final List<QuranEncTranslation> translations;
  final String reciterId; // Not used for now, only Abdul Baset

  const SurahDetailView({
    super.key,
    required this.surahDetail,
    required this.translations,
    required this.reciterId,
  });

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _isLoading = false;
      });
    });
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        _duration = d;
      });
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });
    _fetchAudioUrl();
  }

  @override
  void didUpdateWidget(covariant SurahDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reciterId != widget.reciterId ||
        oldWidget.surahDetail.surahNo != widget.surahDetail.surahNo) {
      _fetchAudioUrl();
      _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
        _duration = Duration.zero;
        _isPlaying = false;
      });
    }
  }

  Future<void> _fetchAudioUrl() async {
    final reciterId = widget.reciterId;
    final surahNo = widget.surahDetail.surahNo;
    final apiUrl =
        'https://api.quran.com/api/v4/chapter_recitations/$reciterId?chapter_number=$surahNo';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioFiles = data['audio_files'] as List<dynamic>;
        if (audioFiles.isNotEmpty) {
          setState(() {
            _audioUrl = audioFiles[0]['audio_url'] as String?;
          });
        } else {
          setState(() {
            _audioUrl = null;
          });
        }
      } else {
        setState(() {
          _audioUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _audioUrl = null;
      });
    }
  }

  Future<void> _onPlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() {
        _isLoading = true;
      });
      if (_audioUrl != null) {
        await _audioPlayer.play(UrlSource(_audioUrl!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              widget.surahDetail.surahNameArabic,
              style: const TextStyle(fontSize: 28, fontFamily: 'Amiri'),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: _isLoading
                  ? const CircularProgressIndicator()
                  : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: (_isLoading || _audioUrl == null) ? null : _onPlayPause,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
          ],
        ),
        if (_audioUrl == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Audio not available for this reciter.'),
          ),
        if (_duration > Duration.zero)
          Column(
            children: [
              Slider(
                value: _position.inMilliseconds.toDouble(),
                min: 0,
                max: _duration.inMilliseconds.toDouble(),
                onChanged: (value) async {
                  final seekTo = Duration(milliseconds: value.toInt());
                  await _audioPlayer.seek(seekTo);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        ...widget.translations.map((t) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.arabicText ?? '',
                  style: const TextStyle(fontSize: 22, fontFamily: 'Amiri'),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  t.translation,
                  style: const TextStyle(fontSize: 16),
                ),
                const Divider(),
              ],
            )),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
