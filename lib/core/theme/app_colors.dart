import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors - Modern Islamic Green with Gold Accents
  static const Color primary = Color(0xFF0F4C3A); // Deep Forest Green
  static const Color primaryLight = Color(0xFF1B5E4B); // Lighter Green
  static const Color primaryDark = Color(0xFF083426); // Darker Green
  static const Color accent = Color(0xFFD4AF37); // Rich Gold
  static const Color accentLight = Color(0xFFE6C55A); // Light Gold

  // Secondary Colors
  static const Color secondary = Color(0xFF2D5A87); // Deep Blue for contrast
  static const Color secondaryLight = Color(0xFF3A6B9C); // Light Blue

  // Background Colors - Modern Material Design 3
  static const Color background = Color(0xFFFCFDF7); // Warm White
  static const Color backgroundDark = Color(0xFF1A1A1A); // Dark Mode
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF5F7FA); // Light Grey
  static const Color surfaceDark = Color(0xFF2D2D2D); // Dark Surface

  // Text Colors - High Contrast for Accessibility
  static const Color textPrimary = Color(0xFF1A1D23); // Almost Black
  static const Color textSecondary = Color(0xFF4A5568); // Medium Grey
  static const Color textTertiary = Color(0xFF718096); // Light Grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on Primary
  static const Color textOnAccent = Color(0xFF1A1D23); // Dark on Gold

  // Status Colors - Modern System Colors
  static const Color success = Color(0xFF22C55E); // Green Success
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color error = Color(0xFFEF4444); // Red Error
  static const Color info = Color(0xFF3B82F6); // Blue Info

  // Prayer Time Specific Colors
  static const Color fajr = Color(0xFF4C1D95); // Deep Purple for dawn
  static const Color sunrise = Color(0xFFF59E0B); // Golden sunrise
  static const Color dhuhr = Color(0xFF059669); // Green for midday
  static const Color asr = Color(0xFFDC6803); // Orange for afternoon
  static const Color maghrib = Color(0xFFDC2626); // Red for sunset
  static const Color isha = Color(0xFF1E40AF); // Blue for night

  // Gradient Colors for Premium Look
  static const List<Color> primaryGradient = [
    Color(0xFF0F4C3A),
    Color(0xFF1B5E4B),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFD4AF37),
    Color(0xFFE6C55A),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
  ];

  // Shadow Colors - Subtle Material Shadows
  static const Color shadowLight = Color(0x08000000);
  static const Color shadowMedium = Color(0x12000000);
  static const Color shadowHeavy = Color(0x20000000);

  // Card Colors for Different Categories
  static const Color quranCard = Color(0xFF6366F1); // Indigo
  static const Color hadithCard = Color(0xFF8B5CF6); // Purple
  static const Color tasbihCard = Color(0xFF06B6D4); // Cyan
  static const Color azkharCard = Color(0xFFF59E0B); // Amber
  static const Color qiblaCard = Color(0xFF10B981); // Emerald
  static const Color donationCard = Color(0xFFEF4444); // Red
}
