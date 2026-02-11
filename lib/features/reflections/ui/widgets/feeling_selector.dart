import 'package:flutter/material.dart';

class FeelingSelector extends StatelessWidget {
  final int selectedSentiment;
  final ValueChanged<int> onChanged;

  const FeelingSelector({
    super.key,
    required this.selectedSentiment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isSelected = value == selectedSentiment;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? _sentimentColor(value).withValues(alpha: 0.2)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(color: _sentimentColor(value), width: 2)
                  : null,
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _sentimentEmoji(value),
                style: TextStyle(fontSize: isSelected ? 32 : 24),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _sentimentEmoji(int value) {
    switch (value) {
      case 1:
        return '😔';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🤲';
      default:
        return '🙂';
    }
  }

  static Color _sentimentColor(int value) {
    switch (value) {
      case 1:
        return const Color(0xFFE57373);
      case 2:
        return const Color(0xFFFFB74D);
      case 3:
        return const Color(0xFFFFD54F);
      case 4:
        return const Color(0xFF81C784);
      case 5:
        return const Color(0xFF64B5F6);
      default:
        return const Color(0xFFFFD54F);
    }
  }

  static String sentimentLabel(int value) {
    switch (value) {
      case 1:
        return 'Distracted';
      case 2:
        return 'Okay';
      case 3:
        return 'Focused';
      case 4:
        return 'Peaceful';
      case 5:
        return 'Deeply Connected';
      default:
        return '';
    }
  }
}
