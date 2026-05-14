import 'package:flutter/material.dart';

class AppTextStyles {
  // Locale State
  static String? _currentLocale;
  static void setLocale(String locale) => _currentLocale = locale;
  static bool get _isAmharic => _currentLocale == 'am';

  static String _arabicFontFamily = 'Amiri';
  static void setArabicFontFamily(String family) => _arabicFontFamily = family;

  static String? get _fontFamily => _isAmharic ? 'Benaiah' : null;

  // Font Families
  static String get primaryFont => _fontFamily ?? 'sans-serif';
  static String get arabicFont => _arabicFontFamily;
  static String get displayFont => _fontFamily ?? 'sans-serif';

  // Display Styles - Large Headers
  static TextStyle get displayLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1A1D23),
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.3,
    letterSpacing: -0.25,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.3,
  );

  // Heading Styles - Modern Typography Scale
  static TextStyle get heading1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  );

  static TextStyle get heading2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  );

  static TextStyle get heading3 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  );

  static TextStyle get heading4 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.5,
  );

  // Body Text Styles
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.6,
  );

  // Add body1 for backward compatibility
  static TextStyle get body1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.6,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF4A5568),
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF718096),
    height: 1.4,
  );

  // Label Styles
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1D23),
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF4A5568),
    height: 1.3,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF718096),
    height: 1.3,
    letterSpacing: 0.5,
  );

  // Arabic Text Styles - Islamic Content
  static TextStyle get arabicLarge => TextStyle(
    fontFamily: arabicFont,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1A1D23),
    height: 2.0,
  );

  static TextStyle get arabicMedium => TextStyle(
    fontFamily: arabicFont,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1A1D23),
    height: 1.8,
  );

  static TextStyle get arabicSmall => TextStyle(
    fontFamily: arabicFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF4A5568),
    height: 1.7,
  );

  // Specialized Styles
  static TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF718096),
    height: 1.4,
  );

  static TextStyle get overline => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF718096),
    height: 1.6,
    letterSpacing: 1.5,
  );

  // Button Styles
  static TextStyle get buttonLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // Prayer Times Styles
  static TextStyle get prayerName => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle get prayerTime => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.1,
    letterSpacing: 0.5,
  );

  static TextStyle get prayerTimeSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    height: 1.2,
  );
}
