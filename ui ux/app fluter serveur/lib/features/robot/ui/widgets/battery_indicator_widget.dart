import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Jauge de batterie animée avec code couleur dynamique et icône de charge.
class BatteryIndicatorWidget extends StatelessWidget {
  final int percentage;
  final bool isCharging;

  const BatteryIndicatorWidget({
    super.key,
    required this.percentage,
    required this.isCharging,
  });

  Color _getBatteryColor() {
    if (percentage > 50) return AppColors.batteryGood;
    if (percentage >= 20) return AppColors.batteryMedium;
    return AppColors.batteryLow;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBatteryColor();
    final clamped = percentage.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône batterie avec niveau rempli
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 18,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: clamped / 100.0),
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isCharging)
                const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.accentCream,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '$clamped %',
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
