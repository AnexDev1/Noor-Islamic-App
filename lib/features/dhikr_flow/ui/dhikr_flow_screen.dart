import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dhikr_provider.dart';
import 'widgets/breathing_circle.dart';
import 'widgets/particle_background.dart';

class DhikrFlowScreen extends ConsumerStatefulWidget {
  const DhikrFlowScreen({super.key});

  @override
  ConsumerState<DhikrFlowScreen> createState() => _DhikrFlowScreenState();
}

class _DhikrFlowScreenState extends ConsumerState<DhikrFlowScreen>
    with TickerProviderStateMixin {
  late AnimationController _textFadeController;
  late AnimationController _celebrationController;
  late Animation<double> _textFade;
  late Animation<double> _celebrationScale;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(
      parent: _textFadeController,
      curve: Curves.easeInOut,
    );
    _textFadeController.forward();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _celebrationScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    // Auto-start session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dhikrSessionProvider.notifier).startSession();
    });
  }

  @override
  void dispose() {
    _textFadeController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _onBreathCycle() {
    final session = ref.read(dhikrSessionProvider);
    if (!session.isActive) return;

    HapticFeedback.lightImpact();
    ref.read(dhikrSessionProvider.notifier).incrementCount();

    final updatedSession = ref.read(dhikrSessionProvider);
    if (updatedSession.isAllComplete) {
      _showCompletionCelebration();
    } else if (updatedSession.count == 0 &&
        updatedSession.currentPhraseIndex > session.currentPhraseIndex) {
      // Phrase changed — animate text transition
      _textFadeController.reset();
      _textFadeController.forward();
      HapticFeedback.heavyImpact();
    }
  }

  void _onTap() {
    final session = ref.read(dhikrSessionProvider);
    if (!session.isActive) return;

    HapticFeedback.lightImpact();
    ref.read(dhikrSessionProvider.notifier).incrementCount();

    final updatedSession = ref.read(dhikrSessionProvider);
    if (updatedSession.isAllComplete) {
      _showCompletionCelebration();
    } else if (updatedSession.count == 0 &&
        updatedSession.currentPhraseIndex > session.currentPhraseIndex) {
      _textFadeController.reset();
      _textFadeController.forward();
      HapticFeedback.heavyImpact();
    }
  }

  void _showCompletionCelebration() {
    setState(() => _showCelebration = true);
    _celebrationController.forward();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dhikrSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Particle background
            const Positioned.fill(
              child: ParticleBackground(
                particleCount: 40,
                particleColor: Color(0xFFD4AF37),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(dhikrSessionProvider.notifier)
                                .endSession();
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        // Streak badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Color(0xFFD4AF37),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${session.streakDays} day streak',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Breathing circle + progress ring + dhikr text
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ProgressRing(
                        progress: session.progress,
                        segments: session.currentPhrase.target,
                        size: 280,
                      ),
                      BreathingCircle(
                        isActive: session.isActive && !_showCelebration,
                        onCycleComplete: _onBreathCycle,
                      ),
                      // Count in center
                      Text(
                        '${session.count}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w200,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Dhikr text
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          session.currentPhrase.arabic,
                          style: const TextStyle(
                            fontSize: 32,
                            fontFamily: 'Amiri',
                            color: Colors.white,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.currentPhrase.transliteration,
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.currentPhrase.translation,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Phase indicator
                  _buildPhaseIndicator(session),

                  const Spacer(),

                  // Hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'Tap anywhere or breathe with the circle',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Celebration overlay
            if (_showCelebration)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: ScaleTransition(
                      scale: _celebrationScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          const Text(
                            'MashaAllah!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You completed your post-salah adhkar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${session.streakDays} day streak 🔥',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(DhikrSessionState session) {
    final totalPhrases = DhikrSessionState.phrases.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPhrases, (i) {
        final isActive = i == session.currentPhraseIndex;
        final isDone = i < session.currentPhraseIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone
                ? const Color(0xFFD4AF37)
                : isActive
                ? const Color(0xFF81C784)
                : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
