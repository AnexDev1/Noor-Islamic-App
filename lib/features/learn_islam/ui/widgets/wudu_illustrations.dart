import 'package:flutter/material.dart';

//
//  WUDU STEP ILLUSTRATIONS — Styled icon cards
//  (No reliable free wudu step images exist on Wikimedia)
//

const _waterColor = Color(0xFF06B6D4);

const Map<int, String> _wuduStepLabels = {
  1: 'Niyyah \u2014 Intention',
  2: 'Wash Hands',
  3: 'Rinse Mouth',
  4: 'Clean Nose',
  5: 'Wash Face',
  6: 'Wash Arms',
  7: 'Wipe Head',
  8: 'Wipe Ears',
  9: 'Wash Feet',
  10: 'Du\u2019a After Wudu',
};

const Map<int, IconData> _stepIcons = {
  1: Icons.favorite_outline,
  2: Icons.back_hand_outlined,
  3: Icons.water_drop_outlined,
  4: Icons.air,
  5: Icons.face,
  6: Icons.fitness_center,
  7: Icons.self_improvement,
  8: Icons.hearing,
  9: Icons.do_not_step_outlined,
  10: Icons.front_hand,
};

const Map<int, String> _stepEmoji = {
  1: '\u2764\uFE0F',
  2: '\u{1F91A}',
  3: '\u{1F4A7}',
  4: '\u{1F4A8}',
  5: '\u{1F9D1}',
  6: '\u{1F4AA}',
  7: '\u{1F64F}',
  8: '\u{1F442}',
  9: '\u{1F9B6}',
  10: '\u{1F932}',
};

/// Returns a beautifully styled icon card for the given Wudu step.
Widget wuduStepIllustration(int stepNum, {double size = 120}) {
  final label = _wuduStepLabels[stepNum] ?? 'Step $stepNum';
  final icon = _stepIcons[stepNum] ?? Icons.water_drop;
  final emoji = _stepEmoji[stepNum] ?? '';

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _waterColor.withValues(alpha: 0.12),
              const Color(0xFF0EA5E9).withValues(alpha: 0.08),
              const Color(0xFF06B6D4).withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: _waterColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background water ripple circles
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _waterColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -5,
              left: -5,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _waterColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Step number badge at top-left
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _waterColor,
                ),
                child: Center(
                  child: Text(
                    '$stepNum',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Main icon
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: size * 0.28)),
                const SizedBox(height: 4),
                Icon(
                  icon,
                  size: size * 0.22,
                  color: _waterColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _waterColor,
        ),
      ),
    ],
  );
}
