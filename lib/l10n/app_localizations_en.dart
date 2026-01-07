// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Noor - Islamic App';

  @override
  String get home => 'Home';

  @override
  String get quran => 'Quran';

  @override
  String get hadith => 'Hadith';

  @override
  String get azkhar => 'Azkhar';

  @override
  String get tasbih => 'Tasbih';

  @override
  String get more => 'More';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get fajr => 'Fajr';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String timeUntil(String prayer) {
    return 'Time until $prayer';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get adhanNotifications => 'Adhan Notifications';

  @override
  String get adhanNotificationsDesc => 'Get notified when prayer time arrives';

  @override
  String get prayerReminders => 'Prayer Reminders';

  @override
  String get prayerRemindersDesc => 'Get reminded 15 minutes before prayer';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get islamicCalendar => 'Islamic Calendar';

  @override
  String get hijriDate => 'Hijri Date';

  @override
  String get exploreNoor => 'Explore Noor';

  @override
  String get discoverFeatures => 'Discover all the features of the app';

  @override
  String get assalamuAlaikum => 'As-salamu Alaykum';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get surah => 'Surah';

  @override
  String get ayah => 'Ayah';

  @override
  String get juz => 'Juz';

  @override
  String get page => 'Page';

  @override
  String get verses => 'Verses';

  @override
  String get listen => 'Listen';

  @override
  String get reciter => 'Reciter';

  @override
  String get book => 'Book';

  @override
  String get chapter => 'Chapter';

  @override
  String get narrator => 'Narrator';

  @override
  String get morning => 'Morning';

  @override
  String get evening => 'Evening';

  @override
  String get afterPrayer => 'After Prayer';

  @override
  String get sleep => 'Sleep';

  @override
  String get count => 'Count';

  @override
  String get target => 'Target';

  @override
  String get reset => 'Reset';

  @override
  String get completed => 'Completed';

  @override
  String get thisSession => 'This Session';

  @override
  String get lifetime => 'Lifetime';

  @override
  String get qiblaDirection => 'Qibla Direction';

  @override
  String get locationPermission => 'Location Permission';

  @override
  String get locationPermissionDesc =>
      'We need location permission to show accurate prayer times and Qibla direction';

  @override
  String get grant => 'Grant';

  @override
  String get deny => 'Deny';

  @override
  String get noInternet => 'No Internet Connection';

  @override
  String get checkConnection =>
      'Please check your internet connection and try again';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get afanOromo => 'Afaan Oromoo';

  @override
  String get undoPrayerConfirmationTitle => 'Undo prayer?';

  @override
  String get undoPrayerConfirmationDesc =>
      'Do you want to undo this prayer entry?';

  @override
  String get undo => 'Undo';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get madhabPreference => 'Madhab Preference';

  @override
  String get selectMadhab => 'Select Madhab';

  @override
  String get updateLocation => 'Update Location';

  @override
  String get updateLocationDesc =>
      'Update your location to get accurate prayer times';

  @override
  String get tapToTestNotification => 'Tap to test notifications';

  @override
  String get testAdhanNotification => 'Test Adhan Notification';

  @override
  String get testReminderNotification => 'Test Reminder Notification';

  @override
  String get adhanNotificationSent => 'Adhan test notification sent';

  @override
  String get reminderNotificationSent => 'Reminder test notification sent';

  @override
  String get refreshPrayerTimes => 'Refresh Prayer Times';

  @override
  String get refreshPrayerTimesDesc =>
      'Fetch latest prayer times from the server';

  @override
  String get refreshingPrayerTimes => 'Refreshing prayer times...';

  @override
  String get updatingLocation => 'Updating location...';

  @override
  String get resetStatistics => 'Reset Statistics';

  @override
  String get statisticsReset => 'Statistics reset successfully';

  @override
  String get resetPrayerStatisticsDesc =>
      'This will reset your prayer statistics.';

  @override
  String get quranChapters => 'Holy Quran Chapters';

  @override
  String surahCount(int count) {
    return '$count Surahs';
  }

  @override
  String get noSurahsFound => 'No Surahs found';
}
