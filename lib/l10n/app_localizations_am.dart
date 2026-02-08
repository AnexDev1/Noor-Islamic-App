// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ኑር - የእስልምና መተግበሪያ';

  @override
  String get home => 'መነሻ';

  @override
  String get quran => 'ቁርዓን';

  @override
  String get hadith => 'ሐዲስ';

  @override
  String get azkhar => 'አዝካር';

  @override
  String get tasbih => 'ተስቢህ';

  @override
  String get more => 'ተጨማሪ';

  @override
  String get prayerTimes => 'የሶላት ሰዓቶች';

  @override
  String get fajr => 'ፈጅር';

  @override
  String get dhuhr => 'ዙህር';

  @override
  String get asr => 'ዐስር';

  @override
  String get maghrib => 'መግሪብ';

  @override
  String get isha => 'ዒሻ';

  @override
  String get nextPrayer => 'ቀጣዩ ሶላት';

  @override
  String timeUntil(String prayer) {
    return 'እስከ $prayer ድረስ ያለው ጊዜ';
  }

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get language => 'ቋንቋ';

  @override
  String get notifications => 'ማሳወቂያዎች';

  @override
  String get adhanNotifications => 'የአዛን ማሳወቂያዎች';

  @override
  String get adhanNotificationsDesc => 'የሶላት ጊዜ ሲደርስ ማሳወቂያ ያግኙ';

  @override
  String get prayerReminders => 'የሶላት ማስታወሻዎች';

  @override
  String get prayerRemindersDesc => 'ከሶላት 15 ደቂቃ በፊት ማስታወሻ ያግኙ';

  @override
  String get darkMode => 'ጨለማ ሁነታ';

  @override
  String get lightMode => 'ብርሃን ሁነታ';

  @override
  String get islamicCalendar => 'የእስልምና ቀን መቁጠሪያ';

  @override
  String get hijriDate => 'የሂጅሪያ ቀን';

  @override
  String get exploreNoor => 'ኑርን ያስሱ';

  @override
  String get discoverFeatures => 'የመተግበሪያውን ሁሉንም ባህሪያት ያግኙ';

  @override
  String get assalamuAlaikum => 'አሰላሙ ዓለይኩም';

  @override
  String get welcome => 'እንኳን በደህና መጡ';

  @override
  String get welcomeBack => 'እንኳን በደህና ተመለሱ';

  @override
  String get loading => 'በመጫን ላይ...';

  @override
  String get error => 'ስህተት';

  @override
  String get retry => 'እንደገና ሞክር';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get save => 'አስቀምጥ';

  @override
  String get done => 'ተጠናቀቀ';

  @override
  String get ok => 'እሺ';

  @override
  String get profile => 'መገለጫ';

  @override
  String get editProfile => 'መገለጫ አርትዕ';

  @override
  String get name => 'ስም';

  @override
  String get gender => 'ጾታ';

  @override
  String get male => 'ወንድ';

  @override
  String get female => 'ሴት';

  @override
  String get about => 'ስለ';

  @override
  String get version => 'ስሪት';

  @override
  String get privacyPolicy => 'የግላዊነት ፖሊሲ';

  @override
  String get termsOfService => 'የአገልግሎት ውሎች';

  @override
  String get contactUs => 'ያግኙን';

  @override
  String get rateApp => 'መተግበሪያውን ይደግፉ';

  @override
  String get shareApp => 'መተግበሪያውን ያጋሩ';

  @override
  String get surah => 'ሱራ';

  @override
  String get ayah => 'አንቀጽ';

  @override
  String get juz => 'ጁዝ';

  @override
  String get page => 'ገጽ';

  @override
  String get verses => 'ቁጥሮች';

  @override
  String get listen => 'ያዳምጡ';

  @override
  String get reciter => 'ቃሪ';

  @override
  String get book => 'መጽሐፍ';

  @override
  String get chapter => 'ምዕራፍ';

  @override
  String get narrator => 'ተራኪ';

  @override
  String get morning => 'ጧት';

  @override
  String get evening => 'ማታ';

  @override
  String get afterPrayer => 'ከሶላት በኋላ';

  @override
  String get sleep => 'እንቅልፍ';

  @override
  String get count => 'ቁጥር';

  @override
  String get target => 'ዒላማ';

  @override
  String get reset => 'ዳግም አስጀምር';

  @override
  String get completed => 'ተጠናቀቀ';

  @override
  String get thisSession => 'ይህ ክፍለ ጊዜ';

  @override
  String get lifetime => 'ጠቅላላ';

  @override
  String get qiblaDirection => 'የቂብላ አቅጣጫ';

  @override
  String get locationPermission => 'የአካባቢ ፈቃድ';

  @override
  String get locationPermissionDesc =>
      'ትክክለኛ የሶላት ጊዜዎችን እና የቂብላ አቅጣጫን ለማሳየት የአካባቢ ፈቃድ ያስፈልገናል';

  @override
  String get grant => 'ፍቀድ';

  @override
  String get deny => 'ከልክል';

  @override
  String get noInternet => 'የበይነመረብ ግንኙነት የለም';

  @override
  String get checkConnection => 'እባክዎ የበይነመረብ ግንኙነትዎን ያረጋግጡ እና እንደገና ይሞክሩ';

  @override
  String get selectLanguage => 'ቋንቋ ይምረጡ';

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

  @override
  String get moreTitle => 'More';

  @override
  String get progressAnalytics => 'Progress & Analytics';

  @override
  String get islamicCalendarTitle => 'Islamic Calendar';

  @override
  String get islamicCalendarSubtitle => 'Hijri dates and Islamic events';

  @override
  String get settingsTitle => 'App Settings';

  @override
  String get settingsSubtitle => 'Notifications, theme, language';

  @override
  String get locationSettingsTitle => 'Location Settings';

  @override
  String get locationSettingsSubtitle => 'Update prayer location';

  @override
  String get backupTitle => 'Backup & Sync';

  @override
  String get backupSubtitle => 'Save your progress';

  @override
  String get supportCommunity => 'Support & Community';

  @override
  String get rateAppTitle => 'Rate Noor';

  @override
  String get rateAppSubtitle => 'Love the app? Rate us!';

  @override
  String get shareAppTitle => 'Share with Friends';

  @override
  String get shareAppSubtitle => 'Spread the word';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackSubtitle => 'Help us improve';

  @override
  String get aboutAppTitle => 'About Noor';

  @override
  String get aboutAppSubtitle => 'App info, privacy & terms';

  @override
  String get qadahTitle => 'Qadah Tracker';

  @override
  String get qadahSubtitle => 'Track and make up missed fasts';

  @override
  String get totalMissed => 'Total Missed';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get remainingDays => 'Remaining Days';

  @override
  String get fastingReminders => 'Fasting Reminders';

  @override
  String get remindMeOn => 'Remind me on';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get incrementPaid => 'Mark Fast as Paid';

  @override
  String get setupQadah => 'Setup Qadah';

  @override
  String get howManyMissed => 'How many days did you miss?';

  @override
  String get timeLeft => 'ቀሪ ጊዜ';

  @override
  String get usingDefaultTimes => 'ነባሪ ሰዓቶችን በመጠቀም (ከመስመር ውጭ)';

  @override
  String get qibla => 'ቂብላ';

  @override
  String get alignPhone => 'ስልክዎን ከቂብላ ጋር ያስተካክሉ';

  @override
  String get searchSurah => 'ሱራ ይፈልጉ...';

  @override
  String get selectReciter => 'አንባቢ ይምረጡ';

  @override
  String get translation => 'ትርጉም';

  @override
  String get showTranslation => 'ትርጉም አሳይ';

  @override
  String get azkarCategories => 'የአዝካር አይነቶች';

  @override
  String get dailyRemembrance => 'ዕለታዊ አዝካር';

  @override
  String get noAzkarFound => 'ምንም አይነት አዝካር አልተገኘም';

  @override
  String get searchAzkar => 'አዝካር ይፈልጉ...';

  @override
  String get hadithCollections => 'የሐዲስ ስብስቦች';

  @override
  String get authenticBooks => 'ትክክለኛ መጽሐፎች';

  @override
  String get noHadithFound => 'ምንም አይነት የሐዲስ መጽሐፍ አልተገኘም';

  @override
  String get searchHadith => 'ሃዲስ ይፈልጉ...';

  @override
  String get readingSettings => 'የንባብ ቅንጅቶች';

  @override
  String get customizeQuranExperience => 'የቁርአን ንባብ ልምድዎን ያብጁ';

  @override
  String get showTranslationDesc => 'ከአረብኛው ጽሑፍ ጎን ትርጉም አሳይ';

  @override
  String get tipFocus => 'ምክር: ለአረብኛ ንባብ ብቻ ትርጉሙን ያጥፉ';

  @override
  String get findingQibla => 'የቀብላ አቅጣጫን በመፈለግ ላይ';

  @override
  String get gettingLocation => 'ቦታዎን በማግኘት እና ወደ ካባ፣ መካ አቅጣጫን በማስላት ላይ...';

  @override
  String get directionToKaaba => 'ወደ ካባ፣ መካ አቅጣጫ';

  @override
  String get unableToFindQibla => 'ቂብላን ማግኘት አልተቻለም';

  @override
  String get unableToFetchQibla =>
      'የቂብላን አቅጣጫ ማግኘት አልተቻለም። እባክዎ የበመረብ ግንኙነትዎን ያረጋግጡ።';

  @override
  String get islamicVideos => 'እስላማዊ ቪዲዮዎች';

  @override
  String get curatedIslamicContent => 'የተራገፉ እስላማዊ ይዘቶች እና ማስታወሻዎች';

  @override
  String get ramadanCountdown => 'ረመዳን የቀረው ጊዜ';

  @override
  String get daysUntilRamadan => 'ቀናት';

  @override
  String get hoursUntilRamadan => 'ሰዓታት';

  @override
  String get minutesUntilRamadan => 'ደቂቃዎች';

  @override
  String get secondsUntilRamadan => 'ሰከንዶች';

  @override
  String get ramadanMubarak => 'ረመዳን ሙባራክ!';

  @override
  String get ramadanKareem => 'ረመዳን ካሪም!';

  @override
  String get ramadanBlessings => 'ይህ ረመዳን ሰላም እና በረከት ይመጣል';
}
