import 'dart:math';
import 'package:flutter/material.dart';

/// Floating particle background for immersive spiritual experiences.
class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;

  const ParticleBackground({
    super.key,
    this.particleCount = 50,
    this.particleColor = const Color(0xFFD4AF37),
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (_) => _generateParticle(),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 3 + 1,
      speed: _random.nextDouble() * 0.0008 + 0.0002,
      opacity: _random.nextDouble() * 0.4 + 0.1,
      drift: (_random.nextDouble() - 0.5) * 0.0003,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particle positions
        for (var p in _particles) {
          p.y -= p.speed;
          p.x += p.drift;
          if (p.y < -0.05) {
            p.y = 1.05;
            p.x = _random.nextDouble();
          }
          if (p.x < -0.05 || p.x > 1.05) {
            p.drift = -p.drift;
          }
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            color: widget.particleColor,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity, drift;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.drift,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        Paint()..color = color.withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
