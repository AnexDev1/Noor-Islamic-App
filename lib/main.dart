import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noor/core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/services/adhan_notification_service.dart';
import 'features/onboarding/ui/splash_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'core/utils/fallback_localization_delegate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureLocationPermission();

  // Initialize notification service
  await AdhanNotificationService.initialize();
  await AdhanNotificationService.requestPermissions();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _ensureLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch user preferences for theme switching
    final preferences = ref.watch(userPreferencesProvider);
    final locale = ref.watch(localeProvider);

    // Update global text styles with current locale
    AppTextStyles.setLocale(locale.languageCode);

    return MaterialApp(
      key: ValueKey(locale.languageCode), // Force rebuild on locale change
      title: AppLocalizations.of(context)?.appTitle ?? 'Noor - Islamic App',
      theme: preferences.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
