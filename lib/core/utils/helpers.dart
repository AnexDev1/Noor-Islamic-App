import 'package:flutter/material.dart';

class AppHelpers {
  // Time-based greeting
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  // Islamic greeting
  static String getIslamicGreeting() {
    return 'Assalamu Alaikum';
  }

  // Format time for Islamic prayers
  static String formatPrayerTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$formattedHour:$minute $period';
  }

  // Get current Hijri date (placeholder - would need proper implementation)
  static String getHijriDate() {
    // This would need a proper Islamic calendar implementation
    return '15 Rajab 1446 AH';
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Sanitize error objects for display in the UI
  static String sanitizeError(Object? error) {
    if (error == null) return 'An unexpected error occurred.';
    final s = error.toString();
    if (s.contains('Failed to load')) return s;
    if (s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Network is unreachable')) {
      return 'Network unavailable. Please check your internet connection and try again.';
    }
    // Fallback generic message
    return 'Something went wrong. Please try again later.';
  }

  // Navigate with slide transition
  static void navigateWithSlideTransition(
    BuildContext context,
    Widget destination,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}
