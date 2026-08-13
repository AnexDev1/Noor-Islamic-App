import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../data/qibla_api.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double? _qiblaDirection;
  double? _heading;
  bool _loading = true;
  String? _error;

  double? get _turn {
    if (_qiblaDirection == null || _heading == null) return null;
    return ((_qiblaDirection! - _heading! + 540) % 360) - 180;
  }

  bool get _isAligned => _turn != null && _turn!.abs() <= 5;

  @override
  void initState() {
    super.initState();
    _initQibla();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() => _heading = event.heading);
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initQibla() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context)!.locationPermissionDesc;
          _loading = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final direction = await QiblaApi.getQiblaDirection(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _qiblaDirection = direction;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.unableToFetchQibla;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 146,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _initQibla,
                tooltip: 'Refresh direction',
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 18,
              ),
              title: Text(
                l10n.qibla,
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              background: Stack(
                children: [
                  PositionedDirectional(
                    end: -22,
                    top: 20,
                    child: Icon(
                      Icons.explore_rounded,
                      size: 142,
                      color: Colors.white.withValues(alpha: .055),
                    ),
                  ),
                  PositionedDirectional(
                    start: 20,
                    bottom: 52,
                    child: Text(
                      l10n.directionToKaaba,
                      style: const TextStyle(
                        color: Color(0xFFB8CAC8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _loading
                    ? const _LoadingState()
                    : _error != null
                    ? _ErrorState(message: _error!, onRetry: _initQibla)
                    : _CompassExperience(
                        qiblaDirection: _qiblaDirection!,
                        heading: _heading,
                        turn: _turn,
                        aligned: _isAligned,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassExperience extends StatelessWidget {
  const _CompassExperience({
    required this.qiblaDirection,
    required this.heading,
    required this.turn,
    required this.aligned,
  });

  final double qiblaDirection;
  final double? heading;
  final double? turn;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final guidance = _guidance(turn);
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: aligned
                ? AppColors.success.withValues(alpha: .1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: aligned
                  ? AppColors.success.withValues(alpha: .34)
                  : const Color(0xFFDCE6E3),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (aligned ? AppColors.success : AppColors.qiblaCard)
                      .withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  aligned ? Icons.check_rounded : guidance.icon,
                  color: aligned ? AppColors.success : AppColors.qiblaCard,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guidance.title,
                      style: AppTextStyles.heading3.copyWith(
                        color: aligned
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(guidance.detail, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (_, constraints) {
            final size = math.min(constraints.maxWidth, 330.0);
            return _CompassDial(size: size, turn: turn ?? 0, aligned: aligned);
          },
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE6E3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: AppColors.qiblaCard,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Direction from your location',
                    style: AppTextStyles.heading4,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'The Kaaba is ${_cardinal(qiblaDirection)} from here.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heading == null
                    ? 'Hold your phone flat and move away from metal objects.'
                    : 'Keep the phone flat while turning your whole body.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static _Guidance _guidance(double? turn) {
    if (turn == null) {
      return const _Guidance(
        'Hold your phone flat',
        'Waiting for a stable compass reading.',
        Icons.screen_rotation_rounded,
      );
    }
    final remaining = turn.abs().round();
    if (remaining <= 5) {
      return const _Guidance(
        'You’re facing the Qibla',
        'Stay in this direction for prayer.',
        Icons.check_rounded,
      );
    }
    final side = turn > 0 ? 'right' : 'left';
    if (remaining <= 15) {
      return _Guidance(
        'Turn slightly $side',
        'About $remaining° remaining.',
        turn > 0 ? Icons.turn_right_rounded : Icons.turn_left_rounded,
      );
    }
    return _Guidance(
      'Turn $side',
      'About $remaining° remaining.',
      turn > 0 ? Icons.turn_right_rounded : Icons.turn_left_rounded,
    );
  }

  static String _cardinal(double bearing) {
    const directions = [
      'north',
      'north-east',
      'east',
      'south-east',
      'south',
      'south-west',
      'west',
      'north-west',
    ];
    return directions[((bearing + 22.5) ~/ 45) % 8];
  }
}

class _Guidance {
  const _Guidance(this.title, this.detail, this.icon);
  final String title;
  final String detail;
  final IconData icon;
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.size,
    required this.turn,
    required this.aligned,
  });

  final double size;
  final double turn;
  final bool aligned;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: aligned
                  ? AppColors.success.withValues(alpha: .55)
                  : const Color(0xFFC8D6D3),
              width: aligned ? 3 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _CompassTicks(aligned: aligned)),
        ),
        const Positioned(
          top: 25,
          child: Text(
            'N',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        AnimatedRotation(
          turns: turn / 360,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: SizedBox.square(
            dimension: size - 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: aligned
                          ? AppColors.success
                          : AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset('assets/macca.png', fit: BoxFit.contain),
                  ),
                ),
                Container(
                  width: 2,
                  height: size * .27,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.transparent,
                        aligned ? AppColors.success : AppColors.accent,
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.navigation_rounded,
                  size: 48,
                  color: aligned ? AppColors.success : AppColors.accent,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aligned ? AppColors.success : AppColors.primaryDark,
          ),
        ),
      ],
    ),
  );
}

class _CompassTicks extends CustomPainter {
  const _CompassTicks({required this.aligned});
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var index = 0; index < 36; index++) {
      final angle = index * 10 * math.pi / 180 - math.pi / 2;
      final major = index % 9 == 0;
      final outside = size.width / 2 - 13;
      final inside = outside - (major ? 13 : 6);
      final paint = Paint()
        ..color = (aligned ? AppColors.success : AppColors.textTertiary)
            .withValues(alpha: major ? .7 : .3)
        ..strokeWidth = major ? 2 : 1;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inside,
        center + Offset(math.cos(angle), math.sin(angle)) * outside,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassTicks oldDelegate) =>
      oldDelegate.aligned != aligned;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .58,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: AppColors.qiblaCard,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.findingQibla,
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.gettingLocation,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFDCE6E3)),
    ),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.location_off_rounded, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.unableToFindQibla,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppLocalizations.of(context)!.retry),
        ),
      ],
    ),
  );
}
