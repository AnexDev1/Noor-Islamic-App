import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PrayerMatScreen extends StatefulWidget {
  const PrayerMatScreen({super.key});

  @override
  State<PrayerMatScreen> createState() => _PrayerMatScreenState();
}

class _PrayerMatScreenState extends State<PrayerMatScreen>
    with TickerProviderStateMixin {
  bool _isActive = false;
  bool _isCompleted = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late AnimationController _mandalaController;
  late AnimationController _breatheController;
  late AnimationController _fadeController;

  final List<String> _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  String _selectedPrayer = 'Fajr';

  @override
  void initState() {
    super.initState();
    _mandalaController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _breatheController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Auto-detect current prayer
    _selectedPrayer = _detectCurrentPrayer();
  }

  String _detectCurrentPrayer() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Fajr';
    if (hour < 12) return 'Dhuhr';
    if (hour < 15) return 'Asr';
    if (hour < 18) return 'Maghrib';
    return 'Isha';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mandalaController.dispose();
    _breatheController.dispose();
    _fadeController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isActive = true;
      _isCompleted = false;
      _elapsedSeconds = 0;
    });

    WakelockPlus.enable();
    _mandalaController.repeat();
    _breatheController.repeat(reverse: true);
    _fadeController.forward();

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });

    HapticFeedback.mediumImpact();
  }

  void _endSession() {
    _timer?.cancel();
    _mandalaController.stop();
    _breatheController.stop();
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    setState(() {
      _isActive = false;
      _isCompleted = true;
    });

    HapticFeedback.heavyImpact();
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildCompletionScreen();
    if (_isActive) return _buildActiveScreen();
    return _buildSetupScreen();
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prayer Mat Mode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🕌', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Focus Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your phone aside and focus on your prayer.\nScreen stays on, distractions blocked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // Prayer selector
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Prayer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: _prayers
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p),
                      selected: _selectedPrayer == p,
                      onSelected: (_) => setState(() => _selectedPrayer = p),
                      selectedColor: const Color(0xFFD4AF37),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: _selectedPrayer == p
                            ? const Color(0xFF0A1628)
                            : Colors.white70,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0A1628),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Begin Prayer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: GestureDetector(
        onDoubleTap: _endSession,
        child: Stack(
          children: [
            // Rotating mandala
            Center(
              child: AnimatedBuilder(
                animation: _mandalaController,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _mandalaController.value * 2 * math.pi,
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: CustomPaint(
                        painter: MandalaPainter(
                          breathValue: _breatheController.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Timer
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPrayer,
                    style: TextStyle(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            // Double tap hint
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Double tap to end session',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text(
                'Prayer Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MashAllah! May Allah accept your $_selectedPrayer',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _summaryItem(
                      '⏱️',
                      '$minutes:${seconds.toString().padLeft(2, '0')}',
                      'Duration',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _summaryItem('🕌', _selectedPrayer, 'Prayer'),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _summaryItem('🌟', 'Focused', 'Status'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A1628),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class MandalaPainter extends CustomPainter {
  final double breathValue;

  MandalaPainter({required this.breathValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw layered geometric patterns
    for (int layer = 0; layer < 4; layer++) {
      final radius =
          maxRadius * (0.4 + layer * 0.15) * (0.95 + breathValue * 0.05);
      final sides = 8 + layer * 4;
      final paint = Paint()
        ..color = const Color(
          0xFFD4AF37,
        ).withValues(alpha: 0.08 + (3 - layer) * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = (2 * math.pi * i / sides);
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);

      // Inner connections
      for (int i = 0; i < sides; i += 2) {
        final angle1 = (2 * math.pi * i / sides);
        final angle2 = (2 * math.pi * ((i + sides ~/ 2) % sides) / sides);
        final x1 = center.dx + radius * math.cos(angle1);
        final y1 = center.dy + radius * math.sin(angle1);
        final x2 = center.dx + radius * math.cos(angle2);
        final y2 = center.dy + radius * math.sin(angle2);
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          paint..strokeWidth = 0.5,
        );
      }
    }

    // Center dot
    final centerPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4 + breathValue * 2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant MandalaPainter oldDelegate) =>
      oldDelegate.breathValue != breathValue;
}
