import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('om'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Noor - Islamic App'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @hadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadith;

  /// No description provided for @azkhar.
  ///
  /// In en, this message translates to:
  /// **'Azkhar'**
  String get azkhar;

  /// No description provided for @tasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbih;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @timeUntil.
  ///
  /// In en, this message translates to:
  /// **'Time until {prayer}'**
  String timeUntil(String prayer);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @adhanNotifications.
  ///
  /// In en, this message translates to:
  /// **'Adhan Notifications'**
  String get adhanNotifications;

  /// No description provided for @adhanNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when prayer time arrives'**
  String get adhanNotificationsDesc;

  /// No description provided for @prayerReminders.
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminders'**
  String get prayerReminders;

  /// No description provided for @prayerRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get reminded 15 minutes before prayer'**
  String get prayerRemindersDesc;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @islamicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Islamic Calendar'**
  String get islamicCalendar;

  /// No description provided for @hijriDate.
  ///
  /// In en, this message translates to:
  /// **'Hijri Date'**
  String get hijriDate;

  /// No description provided for @exploreNoor.
  ///
  /// In en, this message translates to:
  /// **'Explore Noor'**
  String get exploreNoor;

  /// No description provided for @discoverFeatures.
  ///
  /// In en, this message translates to:
  /// **'Discover all the features of the app'**
  String get discoverFeatures;

  /// No description provided for @assalamuAlaikum.
  ///
  /// In en, this message translates to:
  /// **'As-salamu Alaykum'**
  String get assalamuAlaikum;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @surah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// No description provided for @ayah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayah;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @verses.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get verses;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciter;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapter;

  /// No description provided for @narrator.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get narrator;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @afterPrayer.
  ///
  /// In en, this message translates to:
  /// **'After Prayer'**
  String get afterPrayer;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @thisSession.
  ///
  /// In en, this message translates to:
  /// **'This Session'**
  String get thisSession;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @qiblaDirection.
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblaDirection;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermission;

  /// No description provided for @locationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'We need location permission to show accurate prayer times and Qibla direction'**
  String get locationPermissionDesc;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grant;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternet;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again'**
  String get checkConnection;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// No description provided for @afanOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromoo'**
  String get afanOromo;

  /// No description provided for @undoPrayerConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo prayer?'**
  String get undoPrayerConfirmationTitle;

  /// No description provided for @undoPrayerConfirmationDesc.
  ///
  /// In en, this message translates to:
  /// **'Do you want to undo this prayer entry?'**
  String get undoPrayerConfirmationDesc;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @madhabPreference.
  ///
  /// In en, this message translates to:
  /// **'Madhab Preference'**
  String get madhabPreference;

  /// No description provided for @selectMadhab.
  ///
  /// In en, this message translates to:
  /// **'Select Madhab'**
  String get selectMadhab;

  /// No description provided for @updateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// No description provided for @updateLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your location to get accurate prayer times'**
  String get updateLocationDesc;

  /// No description provided for @tapToTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Tap to test notifications'**
  String get tapToTestNotification;

  /// No description provided for @testAdhanNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Adhan Notification'**
  String get testAdhanNotification;

  /// No description provided for @testReminderNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Reminder Notification'**
  String get testReminderNotification;

  /// No description provided for @adhanNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Adhan test notification sent'**
  String get adhanNotificationSent;

  /// No description provided for @reminderNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder test notification sent'**
  String get reminderNotificationSent;

  /// No description provided for @refreshPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Refresh Prayer Times'**
  String get refreshPrayerTimes;

  /// No description provided for @refreshPrayerTimesDesc.
  ///
  /// In en, this message translates to:
  /// **'Fetch latest prayer times from the server'**
  String get refreshPrayerTimesDesc;

  /// No description provided for @refreshingPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Refreshing prayer times...'**
  String get refreshingPrayerTimes;

  /// No description provided for @updatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Updating location...'**
  String get updatingLocation;

  /// No description provided for @resetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics'**
  String get resetStatistics;

  /// No description provided for @statisticsReset.
  ///
  /// In en, this message translates to:
  /// **'Statistics reset successfully'**
  String get statisticsReset;

  /// No description provided for @resetPrayerStatisticsDesc.
  ///
  /// In en, this message translates to:
  /// **'This will reset your prayer statistics.'**
  String get resetPrayerStatisticsDesc;

  /// No description provided for @quranChapters.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran Chapters'**
  String get quranChapters;

  /// No description provided for @surahCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Surahs'**
  String surahCount(int count);

  /// No description provided for @noSurahsFound.
  ///
  /// In en, this message translates to:
  /// **'No Surahs found'**
  String get noSurahsFound;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @progressAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Progress & Analytics'**
  String get progressAnalytics;

  /// No description provided for @islamicCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic Calendar'**
  String get islamicCalendarTitle;

  /// No description provided for @islamicCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hijri dates and Islamic events'**
  String get islamicCalendarSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications, theme, language'**
  String get settingsSubtitle;

  /// No description provided for @locationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get locationSettingsTitle;

  /// No description provided for @locationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update prayer location'**
  String get locationSettingsSubtitle;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get backupTitle;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get backupSubtitle;

  /// No description provided for @supportCommunity.
  ///
  /// In en, this message translates to:
  /// **'Support & Community'**
  String get supportCommunity;

  /// No description provided for @rateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Noor'**
  String get rateAppTitle;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Love the app? Rate us!'**
  String get rateAppSubtitle;

  /// No description provided for @shareAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get shareAppTitle;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spread the word'**
  String get shareAppSubtitle;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get feedbackSubtitle;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About Noor'**
  String get aboutAppTitle;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App info, privacy & terms'**
  String get aboutAppSubtitle;

  /// No description provided for @qadahTitle.
  ///
  /// In en, this message translates to:
  /// **'Qadah Tracker'**
  String get qadahTitle;

  /// No description provided for @qadahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track and make up missed fasts'**
  String get qadahSubtitle;

  /// No description provided for @totalMissed.
  ///
  /// In en, this message translates to:
  /// **'Total Missed'**
  String get totalMissed;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @remainingDays.
  ///
  /// In en, this message translates to:
  /// **'Remaining Days'**
  String get remainingDays;

  /// No description provided for @fastingReminders.
  ///
  /// In en, this message translates to:
  /// **'Fasting Reminders'**
  String get fastingReminders;

  /// No description provided for @remindMeOn.
  ///
  /// In en, this message translates to:
  /// **'Remind me on'**
  String get remindMeOn;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @incrementPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Fast as Paid'**
  String get incrementPaid;

  /// No description provided for @setupQadah.
  ///
  /// In en, this message translates to:
  /// **'Setup Qadah'**
  String get setupQadah;

  /// No description provided for @howManyMissed.
  ///
  /// In en, this message translates to:
  /// **'How many days did you miss?'**
  String get howManyMissed;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time Left'**
  String get timeLeft;

  /// No description provided for @usingDefaultTimes.
  ///
  /// In en, this message translates to:
  /// **'Using default times (offline)'**
  String get usingDefaultTimes;

  /// No description provided for @qibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qibla;

  /// No description provided for @alignPhone.
  ///
  /// In en, this message translates to:
  /// **'Align your phone with the Qibla'**
  String get alignPhone;

  /// No description provided for @searchSurah.
  ///
  /// In en, this message translates to:
  /// **'Search Surah...'**
  String get searchSurah;

  /// No description provided for @selectReciter.
  ///
  /// In en, this message translates to:
  /// **'Select Reciter'**
  String get selectReciter;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show Translation'**
  String get showTranslation;

  /// No description provided for @azkarCategories.
  ///
  /// In en, this message translates to:
  /// **'Azkar Categories'**
  String get azkarCategories;

  /// No description provided for @dailyRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Daily Remembrance'**
  String get dailyRemembrance;

  /// No description provided for @noAzkarFound.
  ///
  /// In en, this message translates to:
  /// **'No Azkar categories found'**
  String get noAzkarFound;

  /// No description provided for @searchAzkar.
  ///
  /// In en, this message translates to:
  /// **'Search Azkar...'**
  String get searchAzkar;

  /// No description provided for @hadithCollections.
  ///
  /// In en, this message translates to:
  /// **'Hadith Collections'**
  String get hadithCollections;

  /// No description provided for @authenticBooks.
  ///
  /// In en, this message translates to:
  /// **'Authentic Books'**
  String get authenticBooks;

  /// No description provided for @noHadithFound.
  ///
  /// In en, this message translates to:
  /// **'No Hadith books found'**
  String get noHadithFound;

  /// No description provided for @searchHadith.
  ///
  /// In en, this message translates to:
  /// **'Search Hadith...'**
  String get searchHadith;

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading Settings'**
  String get readingSettings;

  /// No description provided for @customizeQuranExperience.
  ///
  /// In en, this message translates to:
  /// **'Customize your Quran reading experience'**
  String get customizeQuranExperience;

  /// No description provided for @showTranslationDesc.
  ///
  /// In en, this message translates to:
  /// **'Display translation alongside Arabic text'**
  String get showTranslationDesc;

  /// No description provided for @tipFocus.
  ///
  /// In en, this message translates to:
  /// **'Tip: Turn off translation for a focused Arabic reading experience'**
  String get tipFocus;

  /// No description provided for @findingQibla.
  ///
  /// In en, this message translates to:
  /// **'Finding Qibla Direction'**
  String get findingQibla;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location and calculating the direction to Kaaba...'**
  String get gettingLocation;

  /// No description provided for @directionToKaaba.
  ///
  /// In en, this message translates to:
  /// **'Direction to Kaaba, Mecca'**
  String get directionToKaaba;

  /// No description provided for @unableToFindQibla.
  ///
  /// In en, this message translates to:
  /// **'Unable to Find Qibla'**
  String get unableToFindQibla;

  /// No description provided for @unableToFetchQibla.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch Qibla direction. Please check your connection.'**
  String get unableToFetchQibla;

  /// No description provided for @islamicVideos.
  ///
  /// In en, this message translates to:
  /// **'Islamic Videos'**
  String get islamicVideos;

  /// No description provided for @curatedIslamicContent.
  ///
  /// In en, this message translates to:
  /// **'Curated Islamic content & reminders'**
  String get curatedIslamicContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
