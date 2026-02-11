import 'dart:math';
import 'package:flutter/material.dart';

class BreathingCircle extends StatefulWidget {
  final Duration inhaleDuration;
  final Duration exhaleDuration;
  final VoidCallback onCycleComplete;
  final bool isActive;

  const BreathingCircle({
    super.key,
    this.inhaleDuration = const Duration(seconds: 4),
    this.exhaleDuration = const Duration(seconds: 4),
    required this.onCycleComplete,
    this.isActive = true,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    final total = widget.inhaleDuration + widget.exhaleDuration;
    _controller = AnimationController(vsync: this, duration: total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.isActive) {
          widget.onCycleComplete();
          _controller.forward(from: 0);
        }
      });

    final inhaleRatio =
        widget.inhaleDuration.inMilliseconds / total.inMilliseconds;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: inhaleRatio * 100,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.6,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: (1 - inhaleRatio) * 100,
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 4.0, end: 30.0),
        weight: inhaleRatio * 100,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 30.0, end: 4.0),
        weight: (1 - inhaleRatio) * 100,
      ),
    ]).animate(_controller);

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(BreathingCircle old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.forward();
    } else if (!widget.isActive) {
      _controller.stop();
    }
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
        final scale = _scaleAnimation.value;
        final glow = _glowAnimation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.9),
                  const Color(0xFF1B5E20).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF81C784).withValues(alpha: 0.6),
                  blurRadius: glow,
                  spreadRadius: glow * 0.3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ring that fills with segments as dhikr count progresses.
class ProgressRing extends StatelessWidget {
  final double progress;
  final int segments;
  final double size;

  const ProgressRing({
    super.key,
    required this.progress,
    this.segments = 33,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProgressRingPainter(progress: progress, segments: segments),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final int segments;

  _ProgressRingPainter({required this.progress, required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final completedSegments = (progress * segments).floor();

    for (int i = 0; i < segments; i++) {
      final startAngle = -pi / 2 + (2 * pi * i / segments);
      final sweepAngle = (2 * pi / segments) - 0.04; // gap between segments
      final isCompleted = i < completedSegments;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = isCompleted
            ? const Color(0xFFD4AF37)
            : const Color(0xFF2E7D32).withValues(alpha: 0.2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}
