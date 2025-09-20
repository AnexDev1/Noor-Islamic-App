import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with TickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  int _totalCount = 0;
  String _currentDhikr = 'سُبْحَانَ اللَّهِ';
  String _currentDhikrTranslation = 'Glory be to Allah';

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late AnimationController _rippleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _rippleAnimation;

  final List<Map<String, dynamic>> _dhikrList = [
    {
      'arabic': 'سُبْحَانَ اللَّهِ',
      'translation': 'Glory be to Allah',
      'meaning': 'Praising Allah\'s perfection',
      'count': 33,
      'color': AppColors.primary,
    },
    {
      'arabic': 'الْحَمْدُ لِلَّهِ',
      'translation': 'Praise be to Allah',
      'meaning': 'Thanking Allah for everything',
      'count': 33,
      'color': AppColors.primaryLight,
    },
    {
      'arabic': 'اللَّهُ أَكْبَرُ',
      'translation': 'Allah is Greatest',
      'meaning': 'Declaring Allah\'s greatness',
      'count': 34,
      'color': AppColors.accent,
    },
    {
      'arabic': 'لَا إِلَهَ إِلَّا اللَّهُ',
      'translation': 'There is no god but Allah',
      'meaning': 'Declaration of faith',
      'count': 100,
      'color': AppColors.secondary,
    },
    {
      'arabic': 'أَسْتَغْفِرُ اللَّهَ',
      'translation': 'I seek forgiveness from Allah',
      'meaning': 'Seeking Allah\'s forgiveness',
      'count': 100,
      'color': AppColors.success,
    },
  ];

  int _selectedDhikrIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedData();
    _updateCurrentDhikr();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _updateCurrentDhikr() {
    final selected = _dhikrList[_selectedDhikrIndex];
    setState(() {
      _currentDhikr = selected['arabic'];
      _currentDhikrTranslation = selected['translation'];
      _target = selected['count'];
    });
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = prefs.getInt('tasbih_count') ?? 0;
      _totalCount = prefs.getInt('tasbih_total') ?? 0;
      _selectedDhikrIndex = prefs.getInt('selected_dhikr') ?? 0;
    });
    _updateCurrentDhikr();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', _count);
    await prefs.setInt('tasbih_total', _totalCount);
    await prefs.setInt('selected_dhikr', _selectedDhikrIndex);
  }

  void _increment() async {
    setState(() {
      _count++;
      _totalCount++;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Pulse animation
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Ripple effect
    _rippleController.forward().then((_) => _rippleController.reset());

    // Check if target reached
    if (_count >= _target) {
      _showCompletionCelebration();
    }

    await _saveData();
  }

  void _showCompletionCelebration() {
    HapticFeedback.heavyImpact();
    _celebrationController.forward().then((_) => _celebrationController.reverse());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alhamdulillah! Completed ${_dhikrList[_selectedDhikrIndex]['translation']} ($_target times)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
    _saveData();
    HapticFeedback.mediumImpact();
  }

  void _resetAll() {
    setState(() {
      _count = 0;
      _totalCount = 0;
    });
    _saveData();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];
    final progress = _target > 0 ? _count / _target : 0.0;
    final isCompleted = _count >= _target;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            _buildModernAppBar(),

            // Main Content
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Dhikr Selection
                    _buildDhikrSelection(),

                    const SizedBox(height: 32),

                    // Current Dhikr Display
                    _buildCurrentDhikrDisplay(),

                    const SizedBox(height: 32),

                    // Main Counter
                    Expanded(
                      child: Center(
                        child: _buildInteractiveCounter(selectedDhikr['color'], isCompleted, progress),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Progress Section
                    _buildProgressSection(progress, isCompleted),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _resetAll,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restore,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.radio_button_checked,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Tasbih',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Islamic Prayer Counter',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Total: $_totalCount',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDhikrSelection() {
    return Container(
      height: 120,
      child: PageView.builder(
        itemCount: _dhikrList.length,
        controller: PageController(viewportFraction: 0.85),
        onPageChanged: (index) {
          setState(() {
            _selectedDhikrIndex = index;
            _count = 0; // Reset count when changing dhikr
          });
          _updateCurrentDhikr();
          _saveData();
        },
        itemBuilder: (context, index) {
          final dhikr = _dhikrList[index];
          final isSelected = index == _selectedDhikrIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isSelected ? 0 : 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dhikr['color'] as Color,
                  (dhikr['color'] as Color).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: (dhikr['color'] as Color).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dhikr['arabic'],
                    style: AppTextStyles.arabicMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dhikr['translation'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dhikr['count']}x',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCurrentDhikrDisplay() {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (selectedDhikr['color'] as Color).withValues(alpha: 0.1),
            (selectedDhikr['color'] as Color).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (selectedDhikr['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Arabic Text
          Text(
            _currentDhikr,
            style: AppTextStyles.arabicLarge.copyWith(
              fontSize: 28,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),

          const SizedBox(height: 12),

          // Translation
          Text(
            _currentDhikrTranslation,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Meaning
          Text(
            selectedDhikr['meaning'],
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCounter(Color color, bool isCompleted, double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple Effect
        AnimatedBuilder(
          animation: _rippleAnimation,
          builder: (context, child) {
            return Container(
              width: 240 + (_rippleAnimation.value * 60),
              height: 240 + (_rippleAnimation.value * 60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3 * (1 - _rippleAnimation.value)),
                  width: 2,
                ),
              ),
            );
          },
        ),

        // Outer Ring with Progress
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: AppColors.textTertiary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? AppColors.success : color,
            ),
          ),
        ),

        // Main Counter Button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _celebrationAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * (1 + _celebrationAnimation.value * 0.1),
                  child: GestureDetector(
                    onTap: _increment,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isCompleted
                              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                              : [color, color.withValues(alpha: 0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isCompleted ? AppColors.success : AppColors.primary).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Count number
                          Text(
                            '$_count',
                            style: AppTextStyles.displayLarge.copyWith(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          // Target indicator
                          Text(
                            'of $_target',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tap instruction
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.touch_app,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressSection(double progress, bool isCompleted) {
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Progress',
                    style: AppTextStyles.heading4,
                  ),
                  Text(
                    '$_count of $_target completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isCompleted ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTextStyles.heading4.copyWith(
                    color: isCompleted ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                        : [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lifetime stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Lifetime Total: $_totalCount dhikr',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Reset Count'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textSecondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showTargetDialog(),
            icon: const Icon(Icons.flag, size: 20),
            label: const Text('Set Target'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTargetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempTarget = _target;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Set Custom Target',
            style: AppTextStyles.heading3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How many times would you like to recite this dhikr?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter target count',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  tempTarget = int.tryParse(val) ?? _target;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempTarget > 0) {
                  setState(() {
                    _target = tempTarget;
                    _count = 0;
                  });
                  _saveData();
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Set Target'),
            ),
          ],
        );
      },
    );
  }
}
