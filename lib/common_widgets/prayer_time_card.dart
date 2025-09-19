import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PrayerTimeCard extends StatelessWidget {
  final String prayerName;
  final String prayerTime;
  final bool isDay;

  const PrayerTimeCard({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            prayerTime,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            isDay ? Icons.wb_sunny : Icons.nightlight_round,
            color: isDay ? AppColors.secondary : AppColors.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            prayerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

