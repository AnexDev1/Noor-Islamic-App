import 'dart:math' as math;
import 'package:flutter/material.dart';

class AyahCardTemplate extends StatelessWidget {
  final String arabic;
  final String translation;
  final String reference;
  final String style;

  const AyahCardTemplate({
    super.key,
    required this.arabic,
    required this.translation,
    required this.reference,
    this.style = 'nightSky',
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case 'minimal':
        return _buildMinimal();
      case 'geometric':
        return _buildGeometric();
      case 'watercolor':
        return _buildWatercolor();
      case 'nightSky':
      default:
        return _buildNightSky();
    }
  }

  Widget _buildNightSky() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF1A2A4A), Color(0xFF0F1B30)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1628).withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Stars
          ...List.generate(15, (i) {
            final rng = math.Random(i);
            return Positioned(
              left: rng.nextDouble() * 280,
              top: rng.nextDouble() * 300,
              child: Container(
                width: rng.nextDouble() * 3 + 1,
                height: rng.nextDouble() * 3 + 1,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: rng.nextDouble() * 0.5 + 0.2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '﷽',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24),
              ),
              const SizedBox(height: 20),
              Text(
                arabic,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: 'Amiri',
                  height: 2.0,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 60,
                height: 1,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
              ),
              Text(
                translation,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                reference,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimal() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF5F0E8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabic,
            style: const TextStyle(
              fontSize: 26,
              color: Color(0xFF2C3E50),
              fontFamily: 'Amiri',
              height: 2.0,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          Container(width: 40, height: 2, color: const Color(0xFF0F4C3A)),
          const SizedBox(height: 20),
          Text(
            translation,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5D6D7E),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            reference,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0F4C3A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeometric() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C3A), Color(0xFF1A6B50)],
        ),
      ),
      child: Stack(
        children: [
          // Geometric pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GeometricPatternPainter()),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '☪',
                  style: TextStyle(fontSize: 24, color: Color(0xFFD4AF37)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                arabic,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: 'Amiri',
                  height: 2.0,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              Text(
                '"$translation"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reference,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatercolor() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8D5B7).withValues(alpha: 0.9),
            const Color(0xFFF0E6D2),
            const Color(0xFFE8D5B7).withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '❁',
            style: TextStyle(fontSize: 28, color: Color(0xFF8B6914)),
          ),
          const SizedBox(height: 16),
          Text(
            arabic,
            style: const TextStyle(
              fontSize: 26,
              color: Color(0xFF3E2723),
              fontFamily: 'Amiri',
              height: 2.0,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 30, height: 1, color: const Color(0xFF8B6914)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('✦', style: TextStyle(color: Color(0xFF8B6914))),
              ),
              Container(width: 30, height: 1, color: const Color(0xFF8B6914)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            translation,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5D4037),
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '— $reference',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8B6914),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw geometric Islamic pattern (simplified octagons)
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path();
        final s = spacing * 0.3;
        path.moveTo(x + s, y);
        path.lineTo(x + spacing - s, y);
        path.lineTo(x + spacing, y + s);
        path.lineTo(x + spacing, y + spacing - s);
        path.lineTo(x + spacing - s, y + spacing);
        path.lineTo(x + s, y + spacing);
        path.lineTo(x, y + spacing - s);
        path.lineTo(x, y + s);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
