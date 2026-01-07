import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Locale State
  static String? _currentLocale;
  static void setLocale(String locale) => _currentLocale = locale;
  static bool get _isAmharic => _currentLocale == 'am';

  static String get _fontFamily =>
      _isAmharic ? 'Benaiah' : GoogleFonts.inter().fontFamily!;
  static String get _displayFontFamily =>
      _isAmharic ? 'Benaiah' : GoogleFonts.poppins().fontFamily!;

  // Font Families
  static String get primaryFont => _fontFamily;
  static String get arabicFont => GoogleFonts.amiri().fontFamily!;
  static String get displayFont => _displayFontFamily;

  // Display Styles - Large Headers
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1A1D23),
    height: 1.2,
    letterSpacing: -0.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.3,
    letterSpacing: -0.25,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get displaySmall => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.3,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Heading Styles - Modern Typography Scale
  static TextStyle get heading1 => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get heading2 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get heading3 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get heading4 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Body Text Styles
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.6,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Add body1 for backward compatibility
  static TextStyle get body1 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.6,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF4A5568),
    height: 1.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF718096),
    height: 1.4,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Label Styles
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1D23),
    height: 1.4,
    letterSpacing: 0.1,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF4A5568),
    height: 1.3,
    letterSpacing: 0.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF718096),
    height: 1.3,
    letterSpacing: 0.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Arabic Text Styles - Islamic Content
  static TextStyle get arabicLarge => GoogleFonts.amiri(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 2.0,
  );

  static TextStyle get arabicMedium => GoogleFonts.amiri(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.8,
  );

  static TextStyle get arabicSmall => GoogleFonts.amiri(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF4A5568),
    height: 1.7,
  );

  // Specialized Styles
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF718096),
    height: 1.4,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF718096),
    height: 1.6,
    letterSpacing: 1.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Button Styles
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
    letterSpacing: 0.1,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
    letterSpacing: 0.1,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
    letterSpacing: 0.2,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  // Prayer Times Styles
  static TextStyle get prayerName => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get prayerTime => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.1,
    letterSpacing: 0.5,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);

  static TextStyle get prayerTimeSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    height: 1.2,
  ).copyWith(fontFamily: _isAmharic ? 'Benaiah' : null);
}
