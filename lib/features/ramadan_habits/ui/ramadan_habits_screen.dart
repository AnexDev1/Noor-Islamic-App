import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ramadan_habits_provider.dart';

class RamadanHabitsScreen extends ConsumerWidget {
  const RamadanHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsState = ref.watch(ramadanHabitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ramadan Habits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: habitsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProgressCrescent(habitsState),
                  const SizedBox(height: 24),
                  _buildChallengeGrid(habitsState, ref),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCrescent(RamadanHabitsState habitsState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F4C3A).withValues(alpha: 0.6),
            const Color(0xFF1A6B50).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: CrescentProgressPainter(
                progress: habitsState.progressPercent,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${habitsState.completedCount}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      '/ ${habitsState.challenges.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(habitsState.progressPercent * 100).toInt()}% Complete',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _motivationalMessage(habitsState.progressPercent),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _motivationalMessage(double progress) {
    if (progress >= 1.0) return 'MashAllah! All challenges completed! 🌟';
    if (progress >= 0.75) return 'Almost there! Keep it up! 💪';
    if (progress >= 0.5) return 'Half way through, well done! 🌙';
    if (progress >= 0.25) return 'Great start! Keep going! ✨';
    return 'Begin your Ramadan journey 🤲';
  }

  Widget _buildChallengeGrid(RamadanHabitsState habitsState, WidgetRef ref) {
    final categoryMap = <String, List<RamadanChallenge>>{};
    for (final c in habitsState.challenges) {
      categoryMap.putIfAbsent(c.category, () => []).add(c);
    }

    return Column(
      children: categoryMap.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Row(
                children: [
                  Text(
                    _categoryEmoji(entry.key),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _categoryTitle(entry.key),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                return _buildChallengeTile(entry.value[index], ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChallengeTile(RamadanChallenge challenge, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(ramadanHabitsProvider.notifier).toggleChallenge(challenge.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: challenge.isCompleted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: challenge.isCompleted
                ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: challenge.isCompleted
                    ? const Color(0xFF4CAF50)
                    : Colors.transparent,
                border: Border.all(
                  color: challenge.isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: challenge.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                challenge.titleEn,
                style: TextStyle(
                  color: challenge.isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: challenge.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'prayer':
        return '🕌';
      case 'quran':
        return '📖';
      case 'charity':
        return '💝';
      case 'character':
        return '🌟';
      case 'community':
        return '🤝';
      case 'dhikr':
        return '📿';
      default:
        return '✨';
    }
  }

  String _categoryTitle(String category) {
    switch (category) {
      case 'prayer':
        return 'Prayer';
      case 'quran':
        return 'Quran';
      case 'charity':
        return 'Charity';
      case 'character':
        return 'Character';
      case 'community':
        return 'Community';
      case 'dhikr':
        return 'Dhikr';
      default:
        return category;
    }
  }
}

class CrescentProgressPainter extends CustomPainter {
  final double progress;

  CrescentProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      trackPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [Color(0xFFD4AF37), Color(0xFF4CAF50)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Crescent at progress tip
    if (progress > 0) {
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final tipX = center.dx + radius * math.cos(angle);
      final tipY = center.dy + radius * math.sin(angle);

      final glowPaint = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(tipX, tipY), 6, glowPaint);

      final tipPaint = Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 4, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CrescentProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
