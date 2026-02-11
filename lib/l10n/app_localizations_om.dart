// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appTitle => 'Nuur - Appii Islaamaa';

  @override
  String get home => 'Mana';

  @override
  String get quran => 'Qur\'aana';

  @override
  String get hadith => 'Hadiisa';

  @override
  String get azkhar => 'Azkaar';

  @override
  String get tasbih => 'Tasbiihaa';

  @override
  String get more => 'Dabalata';

  @override
  String get prayerTimes => 'Yeroo Salaataa';

  @override
  String get fajr => 'Fajrii';

  @override
  String get dhuhr => 'Zuhurii';

  @override
  String get asr => 'Asrii';

  @override
  String get maghrib => 'Magriibii';

  @override
  String get isha => 'Ishaa\'ii';

  @override
  String get nextPrayer => 'Salaata Itti Aanu';

  @override
  String timeUntil(String prayer) {
    return 'Yeroo hanga $prayer';
  }

  @override
  String get settings => 'Qindaa\'ina';

  @override
  String get language => 'Afaan';

  @override
  String get notifications => 'Beeksisa';

  @override
  String get adhanNotifications => 'Beeksisa Azaanaa';

  @override
  String get adhanNotificationsDesc =>
      'Yeroon salaataa yoo ga\'u beeksisa argadhu';

  @override
  String get prayerReminders => 'Yaadachiisa Salaataa';

  @override
  String get prayerRemindersDesc =>
      'Salaata dura daqiiqaa 15 yaadachiisa argadhu';

  @override
  String get darkMode => 'Haala Dukkana';

  @override
  String get lightMode => 'Haala Ifaa';

  @override
  String get islamicCalendar => 'Kaaleendarii Islaamaa';

  @override
  String get hijriDate => 'Guyyaa Hijraa';

  @override
  String get exploreNoor => 'Nuur Qoradhu';

  @override
  String get discoverFeatures => 'Tajaajila appii hundaa argadhu';

  @override
  String get assalamuAlaikum => 'Assalaamu Aleykum';

  @override
  String get welcome => 'Baga Nagaan Dhuftan';

  @override
  String get welcomeBack => 'Baga Nagaan Deebitan';

  @override
  String get loading => 'Fe\'aa jira...';

  @override
  String get error => 'Dogoggora';

  @override
  String get retry => 'Irra Deebi\'ii Yaali';

  @override
  String get cancel => 'Haqi';

  @override
  String get save => 'Olkaa\'i';

  @override
  String get done => 'Raawwatame';

  @override
  String get ok => 'Tole';

  @override
  String get profile => 'Piroofaayilii';

  @override
  String get editProfile => 'Piroofaayilii Gulaali';

  @override
  String get name => 'Maqaa';

  @override
  String get gender => 'Saala';

  @override
  String get male => 'Dhiira';

  @override
  String get female => 'Dubartii';

  @override
  String get about => 'Waa\'ee';

  @override
  String get version => 'Gosa';

  @override
  String get privacyPolicy => 'Imaammata Iccitii';

  @override
  String get termsOfService => 'Haala Tajaajilaa';

  @override
  String get contactUs => 'Nu Quunnamaa';

  @override
  String get rateApp => 'Appii Madaali';

  @override
  String get shareApp => 'Appii Qoodaa';

  @override
  String get surah => 'Suuraa';

  @override
  String get ayah => 'Aayata';

  @override
  String get juz => 'Juz\'ii';

  @override
  String get page => 'Fuula';

  @override
  String get verses => 'Aayatoota';

  @override
  String get listen => 'Dhaggeeffadhu';

  @override
  String get reciter => 'Qaarii';

  @override
  String get book => 'Kitaaba';

  @override
  String get chapter => 'Boqonnaa';

  @override
  String get narrator => 'Odeessaa';

  @override
  String get morning => 'Ganama';

  @override
  String get evening => 'Galgala';

  @override
  String get afterPrayer => 'Salaata Booda';

  @override
  String get sleep => 'Hirribaa';

  @override
  String get count => 'Lakkoofsa';

  @override
  String get target => 'Kaayyoo';

  @override
  String get reset => 'Haaromsi';

  @override
  String get completed => 'Xumurame';

  @override
  String get thisSession => 'Yeroo Kana';

  @override
  String get lifetime => 'Walii Galaa';

  @override
  String get qiblaDirection => 'Kallattii Qiblaa';

  @override
  String get locationPermission => 'Hayyama Bakka';

  @override
  String get locationPermissionDesc =>
      'Yeroo salaataa sirrii fi kallattii qiblaa agarsiisuuf hayyama bakka nu barbaachisa';

  @override
  String get grant => 'Hayyami';

  @override
  String get deny => 'Didi';

  @override
  String get noInternet => 'Walqunnamtii Interneetii Hin Jiru';

  @override
  String get checkConnection =>
      'Maaloo walqunnamtii interneetii keessan mirkaneessaa irra deebi\'aa yaalaa';

  @override
  String get selectLanguage => 'Afaan Filadhu';

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
  String get timeLeft => 'Yeroo Hafte';

  @override
  String get usingDefaultTimes => 'Yeroo idilee fayyadamuun (tuunetta malee)';

  @override
  String get qibla => 'Qiblaa';

  @override
  String get alignPhone => 'Bilbila kee Qiblaa wajjin qixxeessi';

  @override
  String get searchSurah => 'Suuraa Barbaadi...';

  @override
  String get selectReciter => 'Qara\'aa Filadhu';

  @override
  String get translation => 'Hiikkaa';

  @override
  String get showTranslation => 'Hiikkaa Agarsiisi';

  @override
  String get azkarCategories => 'Gosoota Azkaaraa';

  @override
  String get dailyRemembrance => 'Azkaara Guyyaa';

  @override
  String get noAzkarFound => 'Azkaaronni homaayyuu hin argamne';

  @override
  String get searchAzkar => 'Azkaara Barbaadi...';

  @override
  String get hadithCollections => 'Walitti Qabama Hadiisaa';

  @override
  String get authenticBooks => 'Kitaabota Sirrii';

  @override
  String get noHadithFound => 'Kitaabonni Hadiisaa hin argamne';

  @override
  String get searchHadith => 'Hadiisa barbaadi...';

  @override
  String get readingSettings => 'Qindaa\'ina Dubbisaa';

  @override
  String get customizeQuranExperience =>
      'Muuxannoo dubbisa Qur\'aana keessan haala barbaaddaniin qopheessaa';

  @override
  String get showTranslationDesc =>
      'Hiika barreeffama Arabiffaa cinaatti agarsiisi';

  @override
  String get tipFocus => 'Gorsa: Dubbisa Arabiffaa qofaaf hiika dhaamsaa';

  @override
  String get findingQibla => 'Kallattii Qiblaa barbaadaa jira';

  @override
  String get gettingLocation =>
      'Iddoo keessan argachuu fi kallattii gara Ka\'abaa shallaguu...';

  @override
  String get directionToKaaba => 'Kallattii gara Ka\'abaa, Makkaa';

  @override
  String get unableToFindQibla => 'Qiblaa argachuu hin dandeenye';

  @override
  String get unableToFetchQibla =>
      'Kallattii Qiblaa argachuu hin dandeenye. Maaloo walqunnamtii keessan mirkaneeffadhaa.';

  @override
  String get islamicVideos => 'Viidiyoo Islaamaa';

  @override
  String get curatedIslamicContent =>
      'Qabeenya Islaamaa fi yaadachiisa filataman';

  @override
  String get ramadanCountdown => 'Ramadaan Lakkoofsi';

  @override
  String get daysUntilRamadan => 'Guyyaa';

  @override
  String get hoursUntilRamadan => 'Sa\'aatii';

  @override
  String get minutesUntilRamadan => 'Daqiiqaa';

  @override
  String get secondsUntilRamadan => 'Sekondii';

  @override
  String get ramadanMubarak => 'Ramadaan Mubaarak!';

  @override
  String get ramadanKareem => 'Ramadaan Kariim!';

  @override
  String get ramadanBlessings =>
      'Ramadaan kana nagaan fi barakaa haa siif haatu';

  @override
  String get learnIslam => 'Islaamaa Baradi';

  @override
  String get listenQuran => 'Qur\'aana Dhageeffadhu';

  @override
  String get learnIslamSubtitle => 'Imala hubannoo keessaniif';

  @override
  String get salah => 'Salaata';

  @override
  String get wudu => 'Wuduu\'a';

  @override
  String get rules => 'Seerawwan';

  @override
  String get videos => 'Viidiyoowwan';

  @override
  String get quiz => 'Qormaata';

  @override
  String get markAsLearned => 'Akka Baratametti Mallatteessi';

  @override
  String get learned => 'Baratameera';

  @override
  String get testYourKnowledge => 'Beekumsa Kee Qori';

  @override
  String get details => 'Bal\'inaan';

  @override
  String get tips => 'Gorsaawwan';

  @override
  String get markSectionComplete => 'Kutaa Xumurametti Mallatteessi';

  @override
  String topics(int count) {
    return 'Mata duree $count';
  }

  @override
  String questionProgress(int current, int total) {
    return 'Gaaffii $current/$total';
  }

  @override
  String score(int score) {
    return 'Qabxii: $score';
  }

  @override
  String get excellent => 'Baay\'ee Gaarii!';

  @override
  String get goodJob => 'Hojii Gaarii!';

  @override
  String get keepLearning => 'Baruu Itti Fufi!';

  @override
  String quizResultMessage(int score, int total, int percentage) {
    return '$total keessaa $score argattan ($percentage%)';
  }
}
