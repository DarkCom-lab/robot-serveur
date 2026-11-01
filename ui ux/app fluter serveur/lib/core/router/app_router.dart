import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/ui/auth_controller.dart';
import '../../features/auth/ui/pin_login_screen.dart';
import '../../features/robot/ui/robot_status_screen.dart';
import '../../features/tasks/ui/task_tracking_screen.dart';
import '../../features/tasks/ui/task_wizard_screen.dart';
import '../config/features_config.dart';

/// Configuration centralisée du routage déclaratif avec GoRouter et gardes d'accès.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. Garde d'authentification : si non connecté, redirection vers /login
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Si déjà connecté et sur /login, rediriger vers l'écran d'accueil robot
      if (isLoggingIn) {
        return '/robot-status';
      }

      // 3. Garde de fonctionnalité (Feature Flag) selon le rôle
      final currentRole = authState.role ?? UserRole.waiter;

      if (state.matchedLocation.startsWith('/task-wizard')) {
        if (!FeaturesConfig.isEnabled(AppFeature.createDeliveryTask, currentRole)) {
          return '/robot-status';
        }
      }

      if (state.matchedLocation.startsWith('/task-tracking')) {
        if (!FeaturesConfig.isEnabled(AppFeature.trackActiveTask, currentRole)) {
          return '/robot-status';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PinLoginScreen(),
      ),
      GoRoute(
        path: '/robot-status',
        name: 'robot-status',
        builder: (context, state) => const RobotStatusScreen(),
      ),
      GoRoute(
        path: '/task-wizard',
        name: 'task-wizard',
        builder: (context, state) => const TaskWizardScreen(),
      ),
      GoRoute(
        path: '/task-tracking/:id',
        name: 'task-tracking',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'TSK-001';
          return TaskTrackingScreen(taskId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF131110),
      body: Center(
        child: Text(
          'Page introuvable : ${state.uri}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ),
  );
});
