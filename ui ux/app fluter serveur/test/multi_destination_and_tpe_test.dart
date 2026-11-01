import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_serveur_flutter/core/storage/table_payment_storage_service.dart';
import 'package:app_serveur_flutter/features/tasks/domain/table_payment_state.dart';
import 'package:app_serveur_flutter/features/tasks/domain/pending_order.dart';
import 'package:app_serveur_flutter/features/robot/data/mock_robot_repository.dart';
import 'package:app_serveur_flutter/features/tasks/data/mock_orders_repository.dart';
import 'package:app_serveur_flutter/features/tasks/data/mock_tasks_repository.dart';
import 'package:app_serveur_flutter/features/tasks/ui/task_wizard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Système de commande multi-destinations & Réorganisation', () {
    late MockRobotRepository robot;
    late MockOrdersRepository ordersRepo;
    late TaskWizardController controller;

    setUp(() {
      robot = MockRobotRepository(speed: 0.001);
      ordersRepo = MockOrdersRepository();
      controller = TaskWizardController(
        ordersRepo: ordersRepo,
        tasksRepo: MockTasksRepository(robot),
        robotRepo: robot,
      );
    });

    tearDown(() {
      controller.dispose();
      robot.dispose();
    });

    test('Sélection rapide par preset (1, 2, 3 tables)', () async {
      final orders = await ordersRepo.getPendingOrders();

      // Preset 1 table
      controller.applyTablesPreset(robot.currentState, orders, 1);
      expect(controller.state.count, 1);
      expect(controller.state.allAssigned, isTrue);

      // Preset 2 tables
      controller.applyTablesPreset(robot.currentState, orders, 2);
      expect(controller.state.count, 2);
      expect(controller.state.allAssigned, isTrue);

      // Preset 3 tables
      controller.applyTablesPreset(robot.currentState, orders, 3);
      expect(controller.state.count, 3);
      expect(controller.state.allAssigned, isTrue);
    });

    test('Réorganisation de l\'ordre des arrêts (Move Up / Move Down)', () async {
      final orders = await ordersRepo.getPendingOrders();
      controller.applyTablesPreset(robot.currentState, orders, 3);

      final initialOrder = controller.state.requests.map((r) => r.order.tableNumber).toList();
      expect(initialOrder.length, 3);

      // Déplacer l'arrêt 1 (2ème élément) vers le haut (1er élément)
      controller.moveDestinationUp(1);
      final afterUpOrder = controller.state.requests.map((r) => r.order.tableNumber).toList();
      expect(afterUpOrder[0], initialOrder[1]);
      expect(afterUpOrder[1], initialOrder[0]);
      expect(afterUpOrder[2], initialOrder[2]);

      // Déplacer le nouvel élément 0 vers le bas
      controller.moveDestinationDown(0);
      final afterDownOrder = controller.state.requests.map((r) => r.order.tableNumber).toList();
      expect(afterDownOrder, initialOrder);
    });

    test('Ajout et retrait libre d\'une destination table', () async {
      final t5 = PendingOrder(
        id: '#CMD-5',
        tableNumber: 'Table 5',
        items: const ['Café'],
        totalPrice: 4.0,
        initialPaymentMode: PaymentMode.none,
        createdAt: DateTime.now(),
      );

      // Au départ, aucune sélection
      expect(controller.state.count, 0);

      // Ajoute Table 5
      controller.toggleTableDestination(t5, robot.currentState);
      expect(controller.state.count, 1);
      expect(controller.state.requests.first.order.tableNumber, 'Table 5');

      // Retouche Table 5 -> la retire
      controller.toggleTableDestination(t5, robot.currentState);
      expect(controller.state.count, 0);
    });
  });

  group('Persistance SharedPreferences du statut TPE des tables', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initialisation par défaut de toutes les tables 1 à 10', () async {
      final storage = TablePaymentStorageService();
      final tables = await storage.loadTablePayments();
      expect(tables.length, 10);
      expect(tables['Table 1']!.status, TableTpeStatus.none);
      expect(tables['Table 10']!.status, TableTpeStatus.none);
    });

    test('Sauvegarde, persistance et rechargement de TPE en attente et payé', () async {
      final storage = TablePaymentStorageService();

      // Table 4 : TPE demandé (en attente)
      await storage.saveSinglePayment(TablePaymentInfo(
        tableNumber: 'Table 4',
        status: TableTpeStatus.pending,
        amount: 18.50,
        updatedAt: DateTime.now(),
      ));

      // Table 7 : Payé
      await storage.saveSinglePayment(TablePaymentInfo(
        tableNumber: 'Table 7',
        status: TableTpeStatus.paid,
        amount: 8.90,
        updatedAt: DateTime.now(),
      ));

      // Simule un redémarrage de l'application en rechargeant depuis un nouveau service
      final reloadedStorage = TablePaymentStorageService();
      final loaded = await reloadedStorage.loadTablePayments();

      expect(loaded['Table 4']!.status, TableTpeStatus.pending);
      expect(loaded['Table 4']!.amount, 18.50);
      expect(loaded['Table 7']!.status, TableTpeStatus.paid);
      expect(loaded['Table 1']!.status, TableTpeStatus.none);
    });
  });
}
