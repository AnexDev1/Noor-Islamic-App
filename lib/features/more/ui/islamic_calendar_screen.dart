import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../common_widgets/custom_cards.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late PageController _pageController;
  int _currentMonthIndex = 0;

  final List<String> _hijriMonths = [
    'Muharram', 'Safar', 'Rabi\' al-awwal', 'Rabi\' al-thani',
    'Jumada al-awwal', 'Jumada al-thani', 'Rajab', 'Sha\'ban',
    'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
  ];

  final List<Map<String, dynamic>> _islamicEvents = [
    {'date': '1-1', 'name': 'Islamic New Year', 'description': 'Beginning of the Hijri calendar'},
    {'date': '10-1', 'name': 'Day of Ashura', 'description': 'Day of fasting and remembrance'},
    {'date': '12-3', 'name': 'Mawlid al-Nabi', 'description': 'Birth of Prophet Muhammad (PBUH)'},
    {'date': '27-7', 'name': 'Isra and Mi\'raj', 'description': 'Night Journey of the Prophet'},
    {'date': '15-8', 'name': 'Lailat al-Bara\'at', 'description': 'Night of Forgiveness'},
    {'date': '1-9', 'name': 'Start of Ramadan', 'description': 'Beginning of the holy month'},
    {'date': '27-9', 'name': 'Lailat al-Qadr', 'description': 'Night of Power'},
    {'date': '1-10', 'name': 'Eid al-Fitr', 'description': 'Festival of Breaking the Fast'},
    {'date': '9-12', 'name': 'Day of Arafat', 'description': 'Day of Hajj pilgrimage'},
    {'date': '10-12', 'name': 'Eid al-Adha', 'description': 'Festival of Sacrifice'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentMonthIndex = DateTime.now().month - 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Simple Hijri date calculation (approximate)
  Map<String, int> _getHijriDate(DateTime gregorianDate) {
    // This is a simplified calculation - in a real app, use a proper Hijri calendar library
    const int hijriEpoch = 227015; // Hijri epoch in Julian days
    int julianDay = _getJulianDay(gregorianDate);
    int daysSinceEpoch = julianDay - hijriEpoch;

    // Approximate Hijri year (354.37 days per year)
    int hijriYear = (daysSinceEpoch / 354.37).floor() + 1;
    int dayOfYear = daysSinceEpoch % 354;

    // Approximate month and day
    int hijriMonth = (dayOfYear / 29.5).floor() + 1;
    int hijriDay = (dayOfYear % 29.5).floor() + 1;

    if (hijriMonth > 12) {
      hijriMonth = 12;
      hijriDay = 29;
    }

    return {
      'year': hijriYear,
      'month': hijriMonth,
      'day': hijriDay,
    };
  }

  int _getJulianDay(DateTime date) {
    int a = (14 - date.month) ~/ 12;
    int y = date.year + 4800 - a;
    int m = date.month + 12 * a - 3;

    return date.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  @override
  Widget build(BuildContext context) {
    final hijriDate = _getHijriDate(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Islamic Calendar'),
      body: Column(
        children: [
          // Current Date Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Today\'s Date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${hijriDate['day']} ${_hijriMonths[hijriDate['month']! - 1]} ${hijriDate['year']} AH',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDate.day} ${_getGregorianMonth(_selectedDate.month)} ${_selectedDate.year}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Calendar Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _hijriMonths[hijriDate['month']! - 1],
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Islamic Events Section
                  _SectionHeader(title: 'Islamic Events This Month'),
                  const SizedBox(height: 12),
                  ..._getEventsForMonth(hijriDate['month']!).map((event) {
                    return _EventCard(
                      title: event['name'],
                      description: event['description'],
                      date: event['date'],
                      isThisMonth: true,
                    );
                  }).toList(),

                  if (_getEventsForMonth(hijriDate['month']!).isEmpty)
                    const _NoEventsCard(),

                  const SizedBox(height: 24),

                  // Upcoming Events
                  _SectionHeader(title: 'Upcoming Events'),
                  const SizedBox(height: 12),
                  ..._getUpcomingEvents(hijriDate['month']!).take(3).map((event) {
                    return _EventCard(
                      title: event['name'],
                      description: event['description'],
                      date: event['date'],
                      isThisMonth: false,
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Islamic Months Info
                  _SectionHeader(title: 'About ${_hijriMonths[hijriDate['month']! - 1]}'),
                  const SizedBox(height: 12),
                  _MonthInfoCard(monthIndex: hijriDate['month']! - 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForMonth(int month) {
    return _islamicEvents.where((event) {
      int eventMonth = int.parse(event['date'].split('-')[1]);
      return eventMonth == month;
    }).toList();
  }

  List<Map<String, dynamic>> _getUpcomingEvents(int currentMonth) {
    return _islamicEvents.where((event) {
      int eventMonth = int.parse(event['date'].split('-')[1]);
      return eventMonth > currentMonth;
    }).toList();
  }

  String _getGregorianMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getMonthInfo(int monthIndex) {
    const monthInfo = [
      'The first month of the Islamic calendar, marking the beginning of the Hijri year.',
      'The second month, known as a month of travel and journey.',
      'The third month, celebrating the birth of Prophet Muhammad (PBUH).',
      'The fourth month, continuing the spring season in the Islamic calendar.',
      'The fifth month, part of the sacred months in Islam.',
      'The sixth month, known for its blessed nature.',
      'The seventh month, one of the four sacred months in Islam.',
      'The eighth month, preparing for the holy month of Ramadan.',
      'The ninth month, the holy month of fasting and spiritual reflection.',
      'The tenth month, celebrating Eid al-Fitr and continuing spiritual growth.',
      'The eleventh month, preparing for the Hajj pilgrimage.',
      'The twelfth month, the month of Hajj and Eid al-Adha celebrations.',
    ];
    return monthInfo[monthIndex];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final bool isThisMonth;

  const _EventCard({
    required this.title,
    required this.description,
    required this.date,
    required this.isThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      // margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isThisMonth
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.split('-')[0],
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isThisMonth ? AppColors.primary : AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isThisMonth)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Today',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoEventsCard extends StatelessWidget {
  const _NoEventsCard();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Icon(
            Icons.calendar_month,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Islamic events this month',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check upcoming events below',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthInfoCard extends StatelessWidget {
  final int monthIndex;
  const _MonthInfoCard({required this.monthIndex});

  @override
  Widget build(BuildContext context) {
    final monthInfo = [
      'The first month of the Islamic calendar, marking the beginning of the Hijri year.',
      'The second month, known as a month of travel and journey.',
      'The third month, celebrating the birth of Prophet Muhammad (PBUH).',
      'The fourth month, continuing the spring season in the Islamic calendar.',
      'The fifth month, part of the sacred months in Islam.',
      'The sixth month, known for its blessed nature.',
      'The seventh month, one of the four sacred months in Islam.',
      'The eighth month, preparing for the holy month of Ramadan.',
      'The ninth month, the holy month of fasting and spiritual reflection.',
      'The tenth month, celebrating Eid al-Fitr and continuing spiritual growth.',
      'The eleventh month, preparing for the Hajj pilgrimage.',
      'The twelfth month, the month of Hajj and Eid al-Adha celebrations.',
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Month Information',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            monthInfo[monthIndex],
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
