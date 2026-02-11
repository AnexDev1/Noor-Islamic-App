import 'package:flutter/material.dart';

class GardenTile extends StatefulWidget {
  final bool isCompleted;
  final bool isToday;
  final int pagesRead;
  final DateTime date;

  const GardenTile({
    super.key,
    required this.isCompleted,
    required this.isToday,
    required this.pagesRead,
    required this.date,
  });

  @override
  State<GardenTile> createState() => _GardenTileState();
}

class _GardenTileState extends State<GardenTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isToday && !widget.isCompleted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isToday && !widget.isCompleted) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: _buildTile(context),
      );
    }
    return _buildTile(context);
  }

  Widget _buildTile(BuildContext context) {
    final weekday = _weekdayAbbr(widget.date.weekday);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          weekday,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _tileColor,
            border: widget.isToday
                ? Border.all(color: const Color(0xFFD4AF37), width: 2)
                : null,
            boxShadow: widget.isCompleted
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isCompleted
                ? _buildGrowth()
                : widget.isToday
                ? const Icon(Icons.add, color: Colors.white54, size: 16)
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 2),
        if (widget.pagesRead > 0)
          Text(
            '${widget.pagesRead}p',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Color get _tileColor {
    if (widget.isCompleted) {
      if (widget.pagesRead >= 5) return const Color(0xFF2E7D32);
      if (widget.pagesRead >= 3) return const Color(0xFF4CAF50);
      return const Color(0xFF81C784);
    }
    return Colors.white.withValues(alpha: 0.1);
  }

  Widget _buildGrowth() {
    if (widget.pagesRead >= 5) {
      return const Text('🌳', style: TextStyle(fontSize: 18));
    } else if (widget.pagesRead >= 3) {
      return const Text('🌿', style: TextStyle(fontSize: 16));
    } else {
      return const Text('🌱', style: TextStyle(fontSize: 14));
    }
  }

  String _weekdayAbbr(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday];
  }
}
