import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class QuranVisuals {
  static const paper = Color(0xFFFFFCF2);
  static const paperDark = Color(0xFF171C19);
  static const ink = Color(0xFF17211C);
  static const inkDark = Color(0xFFF4EFE1);
  static const gold = Color(0xFFC6A15B);
  static const goldDark = Color(0xFFE2C477);

  static Color paperFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? paperDark : paper;

  static Color inkFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? inkDark : ink;

  static Color goldFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? goldDark : gold;
}

class MushafSurface extends StatelessWidget {
  const MushafSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final gold = QuranVisuals.goldFor(context);
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QuranVisuals.paperFor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlighted ? gold : gold.withValues(alpha: 0.34),
            width: highlighted ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _PaperPainter()),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class QuranSurahBanner extends StatelessWidget {
  const QuranSurahBanner({
    super.key,
    required this.arabicName,
    required this.name,
    required this.subtitle,
    this.showBasmala = true,
  });

  final String arabicName;
  final String name;
  final String subtitle;
  final bool showBasmala;

  @override
  Widget build(BuildContext context) {
    final gold = QuranVisuals.goldFor(context);
    final ink = QuranVisuals.inkFor(context);
    return MushafSurface(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: gold.withValues(alpha: 0.55))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.auto_awesome, size: 16, color: gold),
              ),
              Expanded(child: Divider(color: gold.withValues(alpha: 0.55))),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            arabicName,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.arabicLarge.copyWith(
              color: ink,
              fontSize: 35,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            name.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ink.withValues(alpha: 0.76),
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ink.withValues(alpha: 0.58)),
          ),
          if (showBasmala) ...[
            const SizedBox(height: 22),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTextStyles.arabicLarge.copyWith(
                color: AppColors.primary,
                fontSize: 25,
                height: 1.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AyahMedallion extends StatelessWidget {
  const AyahMedallion({super.key, required this.number, this.active = false});

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final gold = QuranVisuals.goldFor(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? AppColors.primary : gold,
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Text(
        _arabicNumber(number),
        textDirection: TextDirection.rtl,
        style: AppTextStyles.arabicSmall.copyWith(
          color: active ? Colors.white : QuranVisuals.inkFor(context),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _arabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((value) => digits[int.parse(value)])
        .join();
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = QuranVisuals.gold.withValues(alpha: 0.035)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    const step = 34.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), 5, paint);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: 7, height: 7),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
