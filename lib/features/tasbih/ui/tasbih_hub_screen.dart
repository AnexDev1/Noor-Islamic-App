import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/tasbih_hub_provider.dart';

/// Unified Tasbih Hub — merges Standard counter, Nafas Dhikr, and Bead Flow
/// into a single cohesive screen with mode tabs.
class TasbihHubScreen extends ConsumerStatefulWidget {
  const TasbihHubScreen({super.key});

  @override
  ConsumerState<TasbihHubScreen> createState() => _TasbihHubScreenState();
}

class _TasbihHubScreenState extends ConsumerState<TasbihHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _celebrationController;
  late AnimationController _beadController;
  late AnimationController _glowController;
  late AnimationController _breathController;

  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;
  late Animation<double> _celebrationAnim;
  late Animation<double> _breathAnim;

  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _celebrationAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _beadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _celebrationController.dispose();
    _beadController.dispose();
    _glowController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  void _onTap() {
    final hub = ref.read(tasbihHubProvider);
    if (_showCelebration) return;

    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
    _rippleController.forward().then((_) => _rippleController.reset());

    switch (hub.mode) {
      case TasbihMode.standard:
      case TasbihMode.beadFlow:
        ref.read(tasbihHubProvider.notifier).increment();
        _beadController.forward(from: 0);
        final updated = ref.read(tasbihHubProvider);
        if (updated.isCompleted) _triggerCelebration();
        break;
      case TasbihMode.nafasDhikr:
        final allDone = ref.read(tasbihHubProvider.notifier).nafasIncrement();
        if (allDone) _triggerCelebration();
        break;
    }
  }

  void _triggerCelebration() {
    setState(() => _showCelebration = true);
    HapticFeedback.heavyImpact();
    _celebrationController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _celebrationController.reset();
        setState(() => _showCelebration = false);
        ref.read(tasbihHubProvider.notifier).resetCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(tasbihHubProvider);

    return Scaffold(
      backgroundColor: hub.mode == TasbihMode.nafasDhikr
          ? const Color(0xFF0A1A0A)
          : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(hub),
            _buildModeSelector(hub),
            Expanded(child: _buildModeContent(hub)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOP BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopBar(TasbihHubState hub) {
    final isDark = hub.mode == TasbihMode.nafasDhikr;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              'Tasbih Hub',
              style: AppTextStyles.heading2.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${hub.streakDays}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODE SELECTOR — 3 horizontal pills
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeSelector(TasbihHubState hub) {
    final isDark = hub.mode == TasbihMode.nafasDhikr;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _modeTab(
            'Counter',
            Icons.touch_app,
            TasbihMode.standard,
            hub,
            isDark,
          ),
          _modeTab('Nafas', Icons.air, TasbihMode.nafasDhikr, hub, isDark),
          _modeTab(
            'Beads',
            Icons.radio_button_checked,
            TasbihMode.beadFlow,
            hub,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _modeTab(
    String label,
    IconData icon,
    TasbihMode mode,
    TasbihHubState hub,
    bool isDark,
  ) {
    final isSelected = hub.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(tasbihHubProvider.notifier).setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary : AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white38 : AppColors.textTertiary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white38 : AppColors.textTertiary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODE-SPECIFIC CONTENT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeContent(TasbihHubState hub) {
    switch (hub.mode) {
      case TasbihMode.standard:
        return _buildStandardMode(hub);
      case TasbihMode.nafasDhikr:
        return _buildNafasMode(hub);
      case TasbihMode.beadFlow:
        return _buildBeadFlowMode(hub);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  STANDARD COUNTER MODE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStandardMode(TasbihHubState hub) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildDhikrPagerCards(hub),
          const SizedBox(height: 16),
          _buildDhikrTextCard(hub),
          const Spacer(),
          _buildCircularCounter(hub, AppColors.primary),
          const Spacer(),
          _buildProgressBar(hub),
          const SizedBox(height: 12),
          _buildActionRow(hub),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Dhikr pager (horizontal cards) ──
  Widget _buildDhikrPagerCards(TasbihHubState hub) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kDhikrPhrases.length,
        itemBuilder: (_, i) {
          final p = kDhikrPhrases[i];
          final selected = i == hub.selectedPhraseIndex;
          final colors = [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.accent,
            AppColors.secondary,
            AppColors.success,
          ];
          return GestureDetector(
            onTap: () => ref.read(tasbihHubProvider.notifier).selectPhrase(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors[i], colors[i].withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors[i].withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
                border: selected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.arabic,
                    style: AppTextStyles.arabicSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.translation,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${p.defaultTarget}x',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Current dhikr display card ──
  Widget _buildDhikrTextCard(TasbihHubState hub) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            hub.currentPhrase.arabic,
            style: AppTextStyles.arabicLarge.copyWith(fontSize: 26),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hub.currentPhrase.translation,
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(hub.currentPhrase.meaning, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ── Circular counter button ──
  Widget _buildCircularCounter(TasbihHubState hub, Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple
        AnimatedBuilder(
          animation: _rippleAnim,
          builder: (_, __) => Container(
            width: 220 + (_rippleAnim.value * 50),
            height: 220 + (_rippleAnim.value * 50),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(
                  alpha: 0.3 * (1 - _rippleAnim.value),
                ),
                width: 2,
              ),
            ),
          ),
        ),
        // Progress ring
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: hub.progress,
            strokeWidth: 6,
            backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(
              hub.isCompleted ? AppColors.success : accentColor,
            ),
          ),
        ),
        // Tap button
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: hub.isCompleted
                      ? [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.7),
                        ]
                      : [accentColor, accentColor.withValues(alpha: 0.7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${hub.count}',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 44,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'of ${hub.target}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    hub.isCompleted ? Icons.check_circle : Icons.touch_app,
                    color: Colors.white70,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Celebration overlay
        if (_showCelebration)
          AnimatedBuilder(
            animation: _celebrationAnim,
            builder: (_, __) => Transform.scale(
              scale: _celebrationAnim.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.9),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Alhamdulillah!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar(TasbihHubState hub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${hub.count} of ${hub.target}',
                  style: AppTextStyles.bodyMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (hub.isCompleted
                                ? AppColors.success
                                : AppColors.primary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(hub.progress * 100).round()}%',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: hub.isCompleted
                          ? AppColors.success
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: hub.progress,
                minHeight: 6,
                backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  hub.isCompleted ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Lifetime: ${hub.totalLifetimeCount} dhikr',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Action buttons row ──
  Widget _buildActionRow(TasbihHubState hub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(tasbihHubProvider.notifier).resetCount();
                HapticFeedback.mediumImpact();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showTargetDialog(),
              icon: const Icon(Icons.flag, size: 18),
              label: const Text('Target'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 2),
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

  void _showTargetDialog() {
    int tempTarget = ref.read(tasbihHubProvider).target;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Custom Target', style: AppTextStyles.heading3),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter target count',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => tempTarget = int.tryParse(v) ?? tempTarget,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempTarget > 0) {
                ref.read(tasbihHubProvider.notifier).setTarget(tempTarget);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAFAS DHIKR MODE — Breath-guided counter
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNafasMode(TasbihHubState hub) {
    final phrase = hub.nafasPhrase;
    final target = phrase.defaultTarget;
    final progress = target > 0 ? (hub.count / target).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Particle-like subtle dots
          ...List.generate(15, (i) {
            final rng = math.Random(i);
            return Positioned(
              left: rng.nextDouble() * MediaQuery.of(context).size.width,
              top: rng.nextDouble() * MediaQuery.of(context).size.height * 0.8,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Opacity(
                  opacity: 0.15 + _glowController.value * 0.2,
                  child: Container(
                    width: 4 + rng.nextDouble() * 4,
                    height: 4 + rng.nextDouble() * 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Phase indicators (3 dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == hub.nafasPhraseIndex;
                    final done = i < hub.nafasPhraseIndex;
                    return Container(
                      width: active ? 30 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: done
                            ? AppColors.success
                            : (active
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.2)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Breathing circle
                AnimatedBuilder(
                  animation: _breathAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _breathAnim.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // Progress ring
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.accent,
                            ),
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.6),
                                AppColors.primary.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${hub.count}',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '/ $target',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Arabic text
                Text(
                  phrase.arabic,
                  style: AppTextStyles.arabicLarge.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  phrase.translation,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Breathe in… Tap… Breathe out…',
                  style: AppTextStyles.caption.copyWith(color: Colors.white30),
                ),
              ],
            ),
          ),

          // Celebration overlay
          if (_showCelebration)
            Center(
              child: AnimatedBuilder(
                animation: _celebrationAnim,
                builder: (_, __) => Transform.scale(
                  scale: _celebrationAnim.value,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.9),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MashaaAllah!',
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All dhikr complete',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BEAD FLOW MODE — Visual bead ring
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBeadFlowMode(TasbihHubState hub) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildDhikrPagerCards(hub),
          const Spacer(),
          // Bead ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _beadController,
                    _glowController,
                  ]),
                  builder: (_, __) => CustomPaint(
                    painter: _BeadRingPainter(
                      totalBeads: hub.target,
                      completedBeads: hub.count,
                      animValue: _beadController.value,
                      glowValue: _glowController.value,
                      beadColor: AppColors.accent,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: hub.isCompleted ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      '${hub.count}',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: hub.isCompleted
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '/ ${hub.target}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Dhikr text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  hub.currentPhrase.arabic,
                  style: AppTextStyles.arabicLarge,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  hub.currentPhrase.translation,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Reset + Next buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(tasbihHubProvider.notifier).resetCount();
                    HapticFeedback.mediumImpact();
                  },
                  icon: const Icon(Icons.refresh),
                  color: AppColors.textSecondary,
                ),
                IconButton(
                  onPressed: () {
                    final next =
                        (hub.selectedPhraseIndex + 1) % kDhikrPhrases.length;
                    ref.read(tasbihHubProvider.notifier).selectPhrase(next);
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.skip_next),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BEAD RING PAINTER
// ═══════════════════════════════════════════════════════════════════

class _BeadRingPainter extends CustomPainter {
  final int totalBeads;
  final int completedBeads;
  final double animValue;
  final double glowValue;
  final Color beadColor;

  _BeadRingPainter({
    required this.totalBeads,
    required this.completedBeads,
    required this.animValue,
    required this.glowValue,
    required this.beadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final beadRadius = math.min(8.0, (2 * math.pi * radius) / (totalBeads * 3));

    for (int i = 0; i < totalBeads; i++) {
      final angle = (2 * math.pi * i / totalBeads) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final isCompleted = i < completedBeads;
      final isCurrent = i == completedBeads;

      final paint = Paint()
        ..color = isCompleted
            ? beadColor
            : (isCurrent
                  ? beadColor.withValues(alpha: 0.5 + glowValue * 0.5)
                  : beadColor.withValues(alpha: 0.15))
        ..style = PaintingStyle.fill;

      final r = isCurrent ? beadRadius * (1 + animValue * 0.3) : beadRadius;
      canvas.drawCircle(Offset(x, y), r, paint);

      if (isCompleted) {
        final glowPaint = Paint()
          ..color = beadColor.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y), r + 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter old) =>
      old.completedBeads != completedBeads ||
      old.animValue != animValue ||
      old.glowValue != glowValue;
}
