import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Font Families
  static String get primaryFont => GoogleFonts.inter().fontFamily!;
  static String get arabicFont => GoogleFonts.amiri().fontFamily!;
  static String get displayFont => GoogleFonts.poppins().fontFamily!;

  // Display Styles - Large Headers
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1A1D23),
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.3,
    letterSpacing: -0.25,
  );

  static TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.3,
  );

  // Heading Styles - Modern Typography Scale
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  );

  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1D23),
    height: 1.4,
  );

  static TextStyle heading4 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1D23),
    height: 1.5,
  );

  // Body Text Styles
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.6,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF4A5568),
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF718096),
    height: 1.4,
  );

  // Label Styles
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1D23),
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF4A5568),
    height: 1.3,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF718096),
    height: 1.3,
    letterSpacing: 0.5,
  );

  // Arabic Text Styles - Islamic Content
  static TextStyle arabicLarge = GoogleFonts.amiri(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 2.0,
  );

  static TextStyle arabicMedium = GoogleFonts.amiri(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF1A1D23),
    height: 1.8,
  );

  static TextStyle arabicSmall = GoogleFonts.amiri(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF4A5568),
    height: 1.7,
  );

  // Specialized Styles
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF718096),
    height: 1.3,
    letterSpacing: 0.4,
  );

  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF718096),
    height: 1.6,
    letterSpacing: 1.5,
  );

  // Button Styles
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
    letterSpacing: 0.1,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // Prayer Times Styles
  static TextStyle prayerName = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle prayerTime = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.1,
    letterSpacing: 0.5,
  );

  static TextStyle prayerTimeSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    height: 1.2,
  );
}
