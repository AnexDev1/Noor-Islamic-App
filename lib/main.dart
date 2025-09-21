import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/ui/splash_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'features/quran/audio/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureLocationPermission();
  runApp(const MyApp());
}

Future<void> _ensureLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor - Islamic App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
