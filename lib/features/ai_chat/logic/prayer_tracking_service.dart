import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTrackingService {
  static const List<String> _prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  // Show prayer completion dialog
  static Future<void> showPrayerCompletionDialog(
    BuildContext context,
    String prayerName,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.mosque, color: Colors.green),
            const SizedBox(width: 8),
            Text('Mark $prayerName as Completed?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Did you complete the $prayerName prayer?'),
            const SizedBox(height: 8),
            const Text(
              '✨ Tracking your prayers helps the AI provide better personalized guidance!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _showCompletionFeedback(context, prayerName);
            },
            icon: const Icon(Icons.check),
            label: const Text('Mark Complete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  // Show encouraging feedback after prayer completion
  static void _showCompletionFeedback(BuildContext context, String prayerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alhamdulillah! $prayerName prayer recorded. May Allah accept it! 🤲',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Get prayer completion status for today
  static Future<Map<String, bool>> getTodayPrayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    Map<String, bool> status = {};
    for (String prayer in _prayerNames) {
      status[prayer] =
          prefs.getBool('prayer_${prayer.toLowerCase()}_$todayKey') ?? false;
    }

    return status;
  }

  // Get prayer statistics summary
  static Future<Map<String, dynamic>> getPrayerStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // Today's prayers
    int todayCount = 0;
    Map<String, bool> todayStatus = {};
    for (String prayer in _prayerNames) {
      bool completed =
          prefs.getBool('prayer_${prayer.toLowerCase()}_$todayKey') ?? false;
      todayStatus[prayer] = completed;
      if (completed) todayCount++;
    }

    // Weekly stats
    int weeklyTotal = 0;
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      for (String prayer in _prayerNames) {
        if (prefs.getBool('prayer_${prayer.toLowerCase()}_$key') ?? false) {
          weeklyTotal++;
        }
      }
    }

    final totalPrayers = prefs.getInt('total_prayers_completed') ?? 0;
    final streak = prefs.getInt('prayer_streak') ?? 0;
    final lastPrayerTime = prefs.getString('last_prayer_time') ?? 'Never';

    return {
      'todayCount': todayCount,
      'todayStatus': todayStatus,
      'weeklyTotal': weeklyTotal,
      'totalPrayers': totalPrayers,
      'streak': streak,
      'lastPrayerTime': lastPrayerTime,
      'weeklyPercentage': ((weeklyTotal / 35) * 100).toStringAsFixed(1),
    };
  }

  // Quick actions for prayer tracking
  static Widget buildQuickPrayerActions(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future: getTodayPrayerStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final status = snapshot.data!;
        final incompletePrayers = status.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

        if (incompletePrayers.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('🎉 All prayers completed today! Alhamdulillah!'),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🕌 Quick Prayer Tracking',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: incompletePrayers.map((prayer) {
                    return ActionChip(
                      avatar: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(prayer),
                      onPressed: () =>
                          showPrayerCompletionDialog(context, prayer),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Prayer statistics widget
  static Widget buildPrayerStats(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getPrayerStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final stats = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Prayer Statistics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Today',
                        '${stats['todayCount']}/5',
                        Icons.today,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'This Week',
                        '${stats['weeklyPercentage']}%',
                        Icons.date_range,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Streak',
                        '${stats['streak']} days',
                        Icons.local_fire_department,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['totalPrayers']}',
                        Icons.mosque,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
