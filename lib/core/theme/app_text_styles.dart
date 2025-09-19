import 'package:flutter/material.dart';

class AppTextStyles {
  // Arabic Font Styles
  static const String arabicFont = 'Amiri';

  // UI Font
  static const String uiFont = 'Inter';

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: uiFont,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E293B),
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: uiFont,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E293B),
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: uiFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: uiFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1E293B),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1E293B),
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF64748B),
  );

  // Arabic Text Styles
  static const TextStyle arabicLarge = TextStyle(
    fontFamily: arabicFont,
    fontSize: 24,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1E293B),
  );

  static const TextStyle arabicMedium = TextStyle(
    fontFamily: arabicFont,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1E293B),
  );

  static const TextStyle arabicSmall = TextStyle(
    fontFamily: arabicFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1E293B),
  );

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: uiFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
