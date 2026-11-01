import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/robot_status.dart';

/// Badge d'état du robot avec point pulsant et étiquette contrastée.
class RobotStatusBadge extends StatefulWidget {
  final RobotStatus status;

  const RobotStatusBadge({super.key, required this.status});

  @override
  State<RobotStatusBadge> createState() => _RobotStatusBadgeState();
}

class _RobotStatusBadgeState extends State<RobotStatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status.color.withOpacity(_pulseAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: status.color.withOpacity(_pulseAnimation.value * 0.7),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: AppTypography.labelLarge.copyWith(
              color: status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
