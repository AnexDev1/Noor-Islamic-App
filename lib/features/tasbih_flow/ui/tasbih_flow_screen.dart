import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';

class TasbihFlowScreen extends StatefulWidget {
  const TasbihFlowScreen({super.key});

  @override
  State<TasbihFlowScreen> createState() => _TasbihFlowScreenState();
}

class _TasbihFlowScreenState extends State<TasbihFlowScreen>
    with TickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  int _selectedDhikrIndex = 0;
  late AnimationController _beadController;
  late AnimationController _glowController;
  late AnimationController _completionController;
  bool _isCompleted = false;

  final List<Map<String, dynamic>> _dhikrList = [
    {
      'arabic': 'سُبْحَانَ اللَّهِ',
      'translation': 'Glory be to Allah',
      'count': 33,
    },
    {
      'arabic': 'الْحَمْدُ لِلَّهِ',
      'translation': 'Praise be to Allah',
      'count': 33,
    },
    {
      'arabic': 'اللَّهُ أَكْبَرُ',
      'translation': 'Allah is Greatest',
      'count': 34,
    },
    {
      'arabic': 'أَسْتَغْفِرُ اللَّهَ',
      'translation': 'I seek forgiveness from Allah',
      'count': 100,
    },
    {
      'arabic': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'translation': 'There is no power except with Allah',
      'count': 33,
    },
  ];

  @override
  void initState() {
    super.initState();
    _target = _dhikrList[_selectedDhikrIndex]['count'];
    _beadController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _beadController.dispose();
    _glowController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _increment() {
    if (_isCompleted) return;
    HapticFeedback.lightImpact();

    setState(() {
      _count++;
      if (_count >= _target) {
        _isCompleted = true;
        _completionController.forward();
        HapticFeedback.heavyImpact();
      }
    });
    _beadController.forward(from: 0);
  }

  void _reset() {
    setState(() {
      _count = 0;
      _isCompleted = false;
    });
    _completionController.reset();
  }

  void _nextDhikr() {
    setState(() {
      _selectedDhikrIndex = (_selectedDhikrIndex + 1) % _dhikrList.length;
      _target = _dhikrList[_selectedDhikrIndex]['count'];
      _count = 0;
      _isCompleted = false;
    });
    _completionController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final dhikr = _dhikrList[_selectedDhikrIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tasbih Flow',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _reset,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _increment,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Bead ring
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _beadController,
                    _glowController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: BeadRingPainter(
                        totalBeads: _target,
                        completedBeads: _count,
                        animationValue: _beadController.value,
                        glowValue: _glowController.value,
                        beadColor: AppColors.accent,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _isCompleted ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      '$_count',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: _isCompleted
                            ? const Color(0xFF4CAF50)
                            : Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '/ $_target',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Dhikr text at bottom
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    dhikr['arabic'],
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dhikr['translation'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Dhikr selector
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dhikrList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedDhikrIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDhikrIndex = index;
                                _target = _dhikrList[index]['count'];
                                _count = 0;
                                _isCompleted = false;
                              });
                              _completionController.reset();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(color: const Color(0xFFD4AF37))
                                    : null,
                              ),
                              child: Text(
                                _dhikrList[index]['arabic'],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isCompleted) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _nextDhikr,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Dhikr'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Tap instruction
            if (_count == 0)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'Tap anywhere to count',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            // Completion overlay
            if (_isCompleted)
              FadeTransition(
                opacity: _completionController,
                child: Container(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BeadRingPainter extends CustomPainter {
  final int totalBeads;
  final int completedBeads;
  final double animationValue;
  final double glowValue;
  final Color beadColor;

  BeadRingPainter({
    required this.totalBeads,
    required this.completedBeads,
    required this.animationValue,
    required this.glowValue,
    required this.beadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final beadRadius = math.max(4.0, math.min(8.0, 200.0 / totalBeads));

    // Draw track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, trackPaint);

    for (int i = 0; i < totalBeads; i++) {
      final angle = (2 * math.pi * i / totalBeads) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final pos = Offset(x, y);

      if (i < completedBeads) {
        // Completed bead
        final isLatest = i == completedBeads - 1;
        final scale = isLatest ? 1.0 + (animationValue * 0.3) : 1.0;

        // Glow for latest bead
        if (isLatest) {
          final glowPaint = Paint()
            ..color = beadColor.withValues(alpha: 0.3 + glowValue * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(pos, beadRadius * scale + 3, glowPaint);
        }

        final paint = Paint()
          ..color = beadColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, beadRadius * scale, paint);

        // Highlight
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(pos.dx - beadRadius * 0.25, pos.dy - beadRadius * 0.25),
          beadRadius * 0.3,
          highlightPaint,
        );
      } else {
        // Incomplete bead
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, beadRadius * 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BeadRingPainter oldDelegate) =>
      oldDelegate.completedBeads != completedBeads ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.glowValue != glowValue;
}
