import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_streak_provider.dart';
import 'widgets/garden_tile.dart';

class QuranStreakScreen extends ConsumerStatefulWidget {
  const QuranStreakScreen({super.key});

  @override
  ConsumerState<QuranStreakScreen> createState() => _QuranStreakScreenState();
}

class _QuranStreakScreenState extends ConsumerState<QuranStreakScreen>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  final TextEditingController _pagesController = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(quranStreakProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mushaf Streak',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStreakHeader(streak),
            const SizedBox(height: 24),
            _buildGardenGrid(streak),
            const SizedBox(height: 24),
            _buildStatsRow(streak),
            const SizedBox(height: 24),
            _buildLogReadingCard(streak),
            const SizedBox(height: 16),
            if (streak.mercyFreezeRemaining > 0 && !streak.todayCompleted)
              _buildMercyFreezeCard(streak),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHeader(QuranStreakState streak) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F4C3A).withValues(alpha: 0.8),
            const Color(0xFF1A6B50).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _flameController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_flameController.value * 0.1),
                child: Text(
                  streak.streakDays > 0 ? '🔥' : '📖',
                  style: const TextStyle(fontSize: 48),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${streak.streakDays}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          Text(
            streak.streakDays == 1 ? 'Day Streak' : 'Days Streak',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (streak.todayCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Today's reading done!",
                      style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGardenGrid(QuranStreakState streak) {
    final gardenDays = streak.getGardenDays(7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🌿 Reading Garden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: gardenDays
                .map(
                  (day) => GardenTile(
                    isCompleted: day.isCompleted,
                    isToday: day.isToday,
                    pagesRead: day.pagesRead,
                    date: day.date,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('🌱', '1-2 pages'),
              const SizedBox(width: 16),
              _legendItem('🌿', '3-4 pages'),
              const SizedBox(width: 16),
              _legendItem('🌳', '5+ pages'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(QuranStreakState streak) {
    return Row(
      children: [
        Expanded(
          child: _statCard('📖', '${streak.totalPagesRead}', 'Total Pages'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard('🏆', '${streak.longestStreak}', 'Best Streak'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            '❄️',
            '${streak.mercyFreezeRemaining}',
            'Mercy Freeze',
          ),
        ),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogReadingCard(QuranStreakState streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.15),
            const Color(0xFFD4AF37).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Log Today\'s Reading',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How many pages did you read?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pagesController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
            decoration: InputDecoration(
              hintText: '55',
              filled: true,
              fillColor: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final pages = int.tryParse(_pagesController.text.trim()) ?? 0;
                if (pages <= 0) return;
                ref.read(quranStreakProvider.notifier).logReading(pages);
                _pagesController.text = '1';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Reading logged')));
              },
              icon: const Icon(Icons.bookmark_add_outlined, size: 20),
              label: const Text(
                'Log Pages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0A1628),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMercyFreezeCard(QuranStreakState streak) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('❄️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mercy Freeze',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Skip a day without breaking your streak',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(quranStreakProvider.notifier).useMercyFreeze();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Mercy Freeze activated ❄️'),
                  backgroundColor: const Color(0xFF1565C0),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              'Use',
              style: TextStyle(color: Color(0xFF64B5F6)),
            ),
          ),
        ],
      ),
    );
  }
}
