import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/noor_wrap_provider.dart';

class NoorWrapScreen extends ConsumerStatefulWidget {
  const NoorWrapScreen({super.key});

  @override
  ConsumerState<NoorWrapScreen> createState() => _NoorWrapScreenState();
}

class _NoorWrapScreenState extends ConsumerState<NoorWrapScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrap = ref.watch(noorWrapProvider);

    final pages = [
      _buildTitlePage(),
      _buildStatPage(
        emoji: '📿',
        value: '${wrap.totalDhikrCount}',
        label: 'Total Dhikr Count',
        subtitle: 'SubhanAllah, Alhamdulillah, Allahu Akbar',
        gradient: [const Color(0xFF1A237E), const Color(0xFF283593)],
      ),
      _buildStatPage(
        emoji: '📖',
        value: '${wrap.totalPagesRead}',
        label: 'Quran Pages Read',
        subtitle: 'Best streak: ${wrap.quranStreakDays} days',
        gradient: [const Color(0xFF0F4C3A), const Color(0xFF1B5E20)],
      ),
      _buildStatPage(
        emoji: '🤲',
        value: '${wrap.totalReflections}',
        label: 'Prayer Reflections',
        subtitle: wrap.topPrayer.isNotEmpty
            ? 'Most reflected prayer: ${wrap.topPrayer}'
            : 'Start reflecting to see insights',
        gradient: [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
      ),
      _buildStatPage(
        emoji: '🌙',
        value: '${wrap.ramadanChallengesCompleted}',
        label: 'Ramadan Challenges',
        subtitle: 'Completed this Ramadan',
        gradient: [const Color(0xFFBF360C), const Color(0xFFD84315)],
      ),
      _buildStatPage(
        emoji: '📅',
        value: '${wrap.daysActive}',
        label: 'Days Active',
        subtitle: 'Your spiritual journey so far',
        gradient: [const Color(0xFF00695C), const Color(0xFF00897B)],
      ),
      _buildClosingPage(wrap),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: pages,
          ),
          // Page indicator
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    width: 6,
                    height: i == _currentPage ? 20 : 6,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlePage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1628), Color(0xFF0F2040)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('☪️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Your Noor Wrap',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A look at your spiritual journey',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.4),
              size: 32,
            ),
            Text(
              'Swipe up',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPage({
    required String emoji,
    required String value,
    required String label,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              _AnimatedCounter(value: value, key: ValueKey('$label-$value')),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosingPage(NoorWrapData wrap) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F4C3A), Color(0xFF0A1628)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 24),
              const Text(
                'Keep Growing',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '"وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 22,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '"And whoever relies upon Allah - then He is sufficient for him."',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '— At-Talaq 65:3',
                style: TextStyle(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0A1628),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Continue Your Journey',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCounter extends StatefulWidget {
  final String value;

  const _AnimatedCounter({super.key, required this.value});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numValue = int.tryParse(widget.value);
    if (numValue == null) {
      return Text(
        widget.value,
        style: const TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD4AF37),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final displayValue = (_animation.value * numValue).toInt();
        return Text(
          '$displayValue',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        );
      },
    );
  }
}
