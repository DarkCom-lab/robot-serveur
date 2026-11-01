import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/utils/haptic_feedback_helper.dart';
import 'auth_controller.dart';
import 'widgets/pin_keypad_widget.dart';

/// Écran de connexion rapide par code PIN 4 chiffres pour les serveurs et gérants.
/// Intègre la photo officielle du robot Fabtino en arrière-plan plein écran
/// avec un overlay sombre et élégant pour une lisibilité parfaite.
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });
      if (_enteredPin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
    });
  }

  void _quickFillPin(String pin) {
    HapticHelper.light();
    setState(() {
      _enteredPin = pin;
    });
    _submitPin();
  }

  Future<void> _submitPin() async {
    final success = await ref.read(authControllerProvider.notifier).login(_enteredPin);
    if (!mounted) return;

    if (success) {
      HapticHelper.success();
      context.go('/robot-status');
    } else {
      HapticHelper.error();
      _shakeController.forward(from: 0.0);
      setState(() {
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Photo officielle du robot en arrière-plan plein écran
          Image.asset(
            'assets/images/robot.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.15),
            errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.background),
          ),

          // 2. Overlay sombre et dégradé pour garantir un contraste et une lisibilité parfaits
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.82),
                  AppColors.background.withOpacity(0.92),
                  AppColors.background.withOpacity(0.98),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Contenu interactif (Logo, PIN, Pavé tactile)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: AppDimensions.space12),

                          // En-tête avec badge robot et titre
                          Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated.withOpacity(0.85),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  color: AppColors.primaryLight,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.space16),
                              const Text(AppStrings.pinLoginTitle, style: AppTypography.displayMedium),
                              const SizedBox(height: AppDimensions.space8),
                              const Text(
                                AppStrings.pinLoginSubtitle,
                                style: AppTypography.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          // Indicateurs visuels des 4 chiffres PIN avec secousse sur erreur
                          AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              final offset = (10 * (1 - _shakeController.value) *
                                  (1 - 2 * (_shakeController.value * 6 % 1)));
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (index) {
                                    final isFilled = index < _enteredPin.length;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 10),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isFilled
                                            ? AppColors.primaryLight
                                            : AppColors.surfaceElevated.withOpacity(0.8),
                                        border: Border.all(
                                          color: isFilled ? AppColors.primary : AppColors.surfaceBorder,
                                          width: 2,
                                        ),
                                        boxShadow: isFilled
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.5),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            : null,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: AppDimensions.space16),
                                if (authState.errorMessage != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusError.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.statusError.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      authState.errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.statusError,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                else if (authState.isLoading)
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 28),
                              ],
                            ),
                          ),

                          // Pavé numérique tactile
                          PinKeypadWidget(
                            onDigitTap: _onDigit,
                            onBackspace: _onBackspace,
                            onClear: _onClear,
                          ),

                          // Raccourcis d'aide cliquables pour la démonstration
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space16, top: AppDimensions.space8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildQuickPinChip('Serveur (1234)', '1234'),
                                const SizedBox(width: 10),
                                _buildQuickPinChip('Gérant (9999)', '9999'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPinChip(String label, String pin) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _quickFillPin(pin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
