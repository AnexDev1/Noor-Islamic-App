import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/ayah_provider.dart';
import 'widgets/ayah_card_template.dart';

class AyahCardScreen extends ConsumerStatefulWidget {
  const AyahCardScreen({super.key});

  @override
  ConsumerState<AyahCardScreen> createState() => _AyahCardScreenState();
}

class _AyahCardScreenState extends ConsumerState<AyahCardScreen> {
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final ayahState = ref.watch(ayahOfDayProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ayah of the Day',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.white70),
            onPressed: () => ref.read(ayahOfDayProvider.notifier).randomAyah(),
            tooltip: 'Random Ayah',
          ),
        ],
      ),
      body: ayahState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : ayahState.todayAyah == null
          ? const Center(
              child: Text(
                'Could not load ayah',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : _buildContent(ayahState),
    );
  }

  Widget _buildContent(AyahOfDayState ayahState) {
    final ayah = ayahState.todayAyah!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Card preview
          RepaintBoundary(
            key: _cardKey,
            child: AyahCardTemplate(
              arabic: ayah.arabic,
              translation: ayah.translation,
              reference: ayah.ref,
              style: ayahState.selectedStyle,
            ),
          ),
          const SizedBox(height: 24),
          // Style selector
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Card Style',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _styleButton('nightSky', '🌙 Night Sky', ayahState),
                _styleButton('minimal', '✨ Minimal', ayahState),
                _styleButton('geometric', '◈ Geometric', ayahState),
                _styleButton('watercolor', '🎨 Parchment', ayahState),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareCard,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A1628),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveCard,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _styleButton(String style, String label, AyahOfDayState ayahState) {
    final isSelected = ayahState.selectedStyle == style;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => ref.read(ayahOfDayProvider.notifier).changeStyle(style),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFFD4AF37))
                : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareCard() async {
    try {
      final bytes = await _captureCard();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ayah_card.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Ayah of the Day - Noor App',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  Future<void> _saveCard() async {
    try {
      final bytes = await _captureCard();
      if (bytes == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/ayah_card_$timestamp.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Card saved! 🎨'),
            backgroundColor: const Color(0xFF0F4C3A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  Future<List<int>?> _captureCard() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}
