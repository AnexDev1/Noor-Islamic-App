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
  String get undoPrayerConfirmationTitle => 'ሶላትን ሰርዝ?';

  @override
  String get undoPrayerConfirmationDesc => 'ይህንን የሶላት መዝገብ መሰረዝ ይፈልጋሉ?';

  @override
  String get undo => 'ቀልብስ';

  @override
  String get aiChat => 'AI ውይይት';

  @override
  String get madhabPreference => 'የመዝሀብ ምርጫ';

  @override
  String get selectMadhab => 'መዝሀብ ይምረጡ';

  @override
  String get updateLocation => 'አካባቢን ያዘምኑ';

  @override
  String get updateLocationDesc => 'ትክክለኛ የሶላት ሰዓቶችን ለማግኘት አካባቢዎን ያዘምኑ';

  @override
  String get tapToTestNotification => 'ማሳወቂያዎችን ለመሞከር ይንኩ';

  @override
  String get testAdhanNotification => 'የአዛን ማሳወቂያን ይሞክሩ';

  @override
  String get testReminderNotification => 'የማስታወሻ ማሳወቂያን ይሞክሩ';

  @override
  String get adhanNotificationSent => 'የአዛን ሙከራ ማሳወቂያ ተልኳል';

  @override
  String get reminderNotificationSent => 'የማስታወሻ ሙከራ ማሳወቂያ ተልኳል';

  @override
  String get refreshPrayerTimes => 'የሶላት ሰዓቶችን ያድሱ';

  @override
  String get refreshPrayerTimesDesc => 'አዳዲስ የሶላት ሰዓቶችን ከሰርቨር ያግኙ';

  @override
  String get refreshingPrayerTimes => 'የሶላት ሰዓቶችን በማደስ ላይ...';

  @override
  String get updatingLocation => 'አካባቢን በማዘመን ላይ...';

  @override
  String get resetStatistics => 'መረጃዎችን ዳግም አስጀምር';

  @override
  String get statisticsReset => 'መረጃዎች በተሳካ ሁኔታ ዳግም ተጀምረዋል';

  @override
  String get resetPrayerStatisticsDesc => 'ይህ የሶላት መረጃዎችዎን ዳግም ያስጀምራል።';

  @override
  String get quranChapters => 'የቅዱስ ቁርኣን ምዕራፎች';

  @override
  String surahCount(int count) {
    return '$count ሱራዎች';
  }

  @override
  String get noSurahsFound => 'ምንም ሱራ አልተገኘም';

  @override
  String get moreTitle => 'ተጨማሪ';

  @override
  String get progressAnalytics => 'እድገት እና ትንታኔ';

  @override
  String get islamicCalendarTitle => 'የእስልምና ቀን መቁጠሪያ';

  @override
  String get islamicCalendarSubtitle => 'የሂጅሪያ ቀናት እና የእስልምና ክስተቶች';

  @override
  String get settingsTitle => 'የመተግበሪያ ቅንብሮች';

  @override
  String get settingsSubtitle => 'ማሳወቂያዎች፣ ገጽታ፣ ቋንቋ';

  @override
  String get locationSettingsTitle => 'የአካባቢ ቅንብሮች';

  @override
  String get locationSettingsSubtitle => 'የሶላት አካባቢን ያዘምኑ';

  @override
  String get backupTitle => 'ምትኬ እና ማመሳሰል';

  @override
  String get backupSubtitle => 'እድገትዎን ያስቀምጡ';

  @override
  String get supportCommunity => 'ድጋፍ እና ማህበረሰብ';

  @override
  String get rateAppTitle => 'ኑርን ይገምግሙ';

  @override
  String get rateAppSubtitle => 'መተግበሪያውን ወድደውታል? ይገምግሙን!';

  @override
  String get shareAppTitle => 'ለጓደኞች ያጋሩ';

  @override
  String get shareAppSubtitle => 'ስለመተግበሪያው ያሳውቁ';

  @override
  String get feedbackTitle => 'አስተያየት';

  @override
  String get feedbackSubtitle => 'እንድናሻሽል ያግዙን';

  @override
  String get aboutAppTitle => 'ስለ ኑር';

  @override
  String get aboutAppSubtitle => 'የመተግበሪያ መረጃ፣ ግላዊነት እና ውሎች';

  @override
  String get qadahTitle => 'የቀዳ መከታተያ';

  @override
  String get qadahSubtitle => 'ያመለጡ ጾሞችን ይከታተሉ እና ይክፈሉ';

  @override
  String get totalMissed => 'ጠቅላላ ያመለጡ';

  @override
  String get totalPaid => 'ጠቅላላ የተከፈሉ';

  @override
  String get remainingDays => 'ቀሪ ቀናት';

  @override
  String get fastingReminders => 'የጾም ማስታወሻዎች';

  @override
  String get remindMeOn => 'አስታውሰኝ በ';

  @override
  String get reminderTime => 'የማስታወሻ ሰዓት';

  @override
  String get incrementPaid => 'ጾምን እንደተከፈለ ምልክት ያድርጉ';

  @override
  String get setupQadah => 'ቀዳን ያዋቅሩ';

  @override
  String get howManyMissed => 'ስንት ቀናት አመለጡዎት?';

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
  String get islamicVideos => 'ዳዕዋ';

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

  @override
  String get learnIslam => 'እስልምናን ተማር';

  @override
  String get listenQuran => 'ቁርኣን ያድምጡ';

  @override
  String get learnIslamSubtitle => 'ሳላህ፣ ውዱ፣ ደንብ እና የቪዲዮ ትምህርቶች';

  @override
  String get salah => 'ሶላት';

  @override
  String get wudu => 'ውዱእ';

  @override
  String get rules => 'ደንቦች';

  @override
  String get videos => 'ቪዲዮዎች';

  @override
  String get quiz => 'ፈተና';

  @override
  String get markAsLearned => 'እንደተማርኩ ምልክት አድርግ';

  @override
  String get learned => 'ተምሯል';

  @override
  String get testYourKnowledge => 'እውቀትዎን ይፈትኑ';

  @override
  String get details => 'ዝርዝሮች';

  @override
  String get tips => 'ምክሮች';

  @override
  String get markSectionComplete => 'ክፍሉን እንደተጠናቀቀ ምልክት አድርግ';

  @override
  String topics(int count) {
    return '$count ርዕሶች';
  }

  @override
  String questionProgress(int current, int total) {
    return 'ጥያቄ $current/$total';
  }

  @override
  String score(int score) {
    return 'ውጤት: $score';
  }

  @override
  String get excellent => 'እጅግ በጣም ጥሩ!';

  @override
  String get goodJob => 'ጥሩ ሥራ!';

  @override
  String get keepLearning => 'መማርዎን ቀጥሉ!';

  @override
  String quizResultMessage(int score, int total, int percentage) {
    return 'ከ$total ውስጥ $score አስመዝግበዋል ($percentage%)';
  }

  @override
  String get tajweedHifzMode => 'ታጅወድ እና ሂፍዝ ሁነታ';

  @override
  String get tajweedHifzSubtitle => 'በአንደበት በቅርጥ ንባብ እና ድግግሞሽ';

  @override
  String get prayerMatMode => 'የጸሎት ወንጌል ሁነታ';

  @override
  String get prayerMatSubtitle => 'ትዕይንት ነጻ ትኩረት ሰዓት';

  @override
  String get noorWrap => 'ኑር ጠቅላላ';

  @override
  String get noorWrapSubtitle => 'የእርስዎ መንፈሳዊ ጉዞ ማጠቃለያ';

  @override
  String get tasbihSubtitle => 'ቆጣሪ፣ ናፋስ ዝክር እና ዝርዝር ሃብር';

  @override
  String get bookmarksSubtitle => 'የተቀመጡ ቁርዓን፣ ሐዲስ እና አዝካር ንጥሎች';

  @override
  String get listenQuranSubtitle => 'ስትሪም ኦዲዮ ከጀርባ ሎጋር ጋር';

  @override
  String get quranStreakSubtitle => 'የተለየ ቁርዓን ንባብ ይከታተሉ';

  @override
  String get reflectionsSubtitle => 'የእርስዎ ጸሎት ልምዶች መመዝገቢያ';

  @override
  String get ayahCardSubtitle => 'አሪሙ የሚጋራ ቁርዓን ካርዶች';

  @override
  String get ramadanHabitsSubtitle => '30 ቀናት ፈተና ሰሌዳ';

  @override
  String get zikrReminders => 'ዝክር ማስታወሻዎች';

  @override
  String get softZikrReminders => 'ለስ ዝክር ማስታወሻዎች';

  @override
  String get reminderInterval => 'ማስታወሻ ጊዜ';

  @override
  String get reminderZikr => 'ማስታወሻ ዝክር';

  @override
  String get appearanceSettings => 'ገጽታ';

  @override
  String get darkThemeTitle => 'ጨለማ ሥርዓተ ዓለም';

  @override
  String get darkThemeSubtitle => 'ወፍራ ቀለም ፎቅ ይጠቀሙ';

  @override
  String get arabicFontTitle => 'የአረቢ ፊት';
}
