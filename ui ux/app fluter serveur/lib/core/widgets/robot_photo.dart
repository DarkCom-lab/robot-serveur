import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Photo du robot Fabtino (assets/images/robot.png).
///
/// - Apparition en fondu quand l'image est prête.
/// - Si l'image ne charge pas : un visuel de remplacement propre
///   (icône robot + nom), jamais d'écran cassé.
class RobotPhoto extends StatelessWidget {
  static const String assetPath = 'assets/images/robot.png';

  final double height;
  final double borderRadius;
  final Alignment alignment;
  final BoxFit fit;

  /// Texte en bas à gauche (ex. « ROBOT 01 »). `null` = aucun.
  final String? caption;

  /// Petit contenu en bas à droite (ex. badge de statut).
  final Widget? trailing;

  const RobotPhoto({
    super.key,
    this.height = 170,
    this.borderRadius = 20,
    this.alignment = const Alignment(0, -0.1),
    this.fit = BoxFit.cover,
    this.caption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverlay = caption != null || trailing != null;
    return Semantics(
      image: true,
      label: 'Photo du robot Fabtino',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.surfaceElevated),
              Image.asset(
                assetPath,
                fit: fit,
                alignment: alignment,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, __, ___) => const RobotPhotoFallback(),
              ),
              if (hasOverlay)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.45, 1],
                      colors: [Color(0x00131110), Color(0xE6131110)],
                    ),
                  ),
                ),
              if (caption != null)
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Text(caption!, style: AppTypography.titleLarge),
                ),
              if (trailing != null) Positioned(right: 12, bottom: 10, child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visuel affiché si la photo ne peut pas être chargée.
class RobotPhotoFallback extends StatelessWidget {
  const RobotPhotoFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('robot-photo-fallback'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHighlight, AppColors.surface],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 56, color: AppColors.primaryLight),
          SizedBox(height: 6),
          Text('Fabtino', style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}
