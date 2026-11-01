import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';

/// Pavé numérique ergonomique pour une saisie ultra-rapide du PIN d'une seule main.
class PinKeypadWidget extends StatelessWidget {
  final Function(String digit) onDigitTap;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;

  const PinKeypadWidget({
    super.key,
    required this.onDigitTap,
    required this.onBackspace,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['clear', '0', 'backspace'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: _buildKey(context, key),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    final isClear = key == 'clear';
    final isBackspace = key == 'backspace';
    final isAction = isClear || isBackspace;

    return Material(
      color: isAction ? Colors.transparent : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: InkWell(
        onTap: () {
          HapticHelper.light();
          if (isBackspace) {
            onBackspace();
          } else if (isClear) {
            onClear?.call();
          } else {
            onDigitTap(key);
          }
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        splashColor: AppColors.primary.withOpacity(0.3),
        child: Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isAction ? Colors.transparent : AppColors.surfaceBorder,
              width: 1.2,
            ),
          ),
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, color: AppColors.textPrimary, size: 26)
              : isClear
                  ? const Text('C', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMuted))
                  : Text(key, style: AppTypography.displayMedium),
        ),
      ),
    );
  }
}
