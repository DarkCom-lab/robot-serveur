import 'package:flutter_test/flutter_test.dart';
import 'package:app_serveur_flutter/core/config/features_config.dart';
import 'package:app_serveur_flutter/features/auth/domain/user_role.dart';

void main() {
  group('Système de Feature Flags et Permissions par Rôle', () {
    test('Le rôle Serveur (waiter) doit avoir accès aux fonctions initiales', () {
      expect(FeaturesConfig.isEnabled(AppFeature.pinLogin, UserRole.waiter), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.robotStatus, UserRole.waiter), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.createDeliveryTask, UserRole.waiter), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.trackActiveTask, UserRole.waiter), isTrue);
    });

    test('Le rôle Serveur (waiter) doit avoir les fonctionnalités avancées DÉSACTIVÉES', () {
      expect(FeaturesConfig.isEnabled(AppFeature.cancelTask, UserRole.waiter), isFalse);
      expect(FeaturesConfig.isEnabled(AppFeature.recallRobotToBase, UserRole.waiter), isFalse);
      expect(FeaturesConfig.isEnabled(AppFeature.deliveryHistory, UserRole.waiter), isFalse);
      expect(FeaturesConfig.isEnabled(AppFeature.emergencyStop, UserRole.waiter), isFalse);
      expect(FeaturesConfig.isEnabled(AppFeature.analyticsStats, UserRole.waiter), isFalse);
      expect(FeaturesConfig.isEnabled(AppFeature.pushNotifications, UserRole.waiter), isFalse);
    });

    test('Le rôle Gérant (manager) doit avoir accès aux privilèges avancés', () {
      expect(FeaturesConfig.isEnabled(AppFeature.cancelTask, UserRole.manager), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.recallRobotToBase, UserRole.manager), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.deliveryHistory, UserRole.manager), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.emergencyStop, UserRole.manager), isTrue);
      expect(FeaturesConfig.isEnabled(AppFeature.analyticsStats, UserRole.manager), isTrue);
    });

    test('Chaque fonctionnalité désactivée doit fournir une explication claire', () {
      final reason = FeaturesConfig.getDisabledReason(AppFeature.emergencyStop);
      expect(reason, contains('Gérant'));
    });
  });
}
