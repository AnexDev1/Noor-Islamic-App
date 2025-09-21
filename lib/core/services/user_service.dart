import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _keyName = 'user_name';
  static const String _keyEmail = 'user_email';
  static const String _keyLocation = 'user_location';
  static const String _keyGender = 'user_gender';
  static const String _keyLanguage = 'user_language';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyProfilePicture = 'user_profile_picture';

  // Get user information
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName) ?? 'User';
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail) ?? '';
  }

  static Future<String> getUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocation) ?? '';
  }

  static Future<String> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGender) ?? 'Male';
  }

  static Future<String> getUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'English';
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Set user information
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  static Future<void> setUserLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocation, location);
  }

  static Future<void> setUserGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGender, gender);
  }

  static Future<void> setUserLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  // Get personalized greeting based on gender and time
  static Future<String> getPersonalizedGreeting() async {
    final name = await getUserName();
    final gender = await getUserGender();
    final hour = DateTime.now().hour;

    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good Morning';
    } else if (hour < 17) {
      timeGreeting = 'Good Afternoon';
    } else if (hour < 21) {
      timeGreeting = 'Good Evening';
    } else {
      timeGreeting = 'Good Night';
    }

    return '$timeGreeting, $name';
  }

  static Future<String> getIslamicGreeting() async {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'As-salamu Alaykum';
    } else if (hour < 17) {
      return 'Ahlan wa Sahlan';
    } else {
      return 'As-salamu Alaykum';
    }
  }

  // Clear all user data (for reset functionality)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyLocation);
    await prefs.remove(_keyGender);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyOnboardingCompleted);
  }

  // Get user profile data as a map
  static Future<Map<String, dynamic>> getUserProfile() async {
    return {
      'name': await getUserName(),
      'email': await getUserEmail(),
      'location': await getUserLocation(),
      'gender': await getUserGender(),
      'language': await getUserLanguage(),
      'notifications': await getNotificationsEnabled(),
    };
  }
}
