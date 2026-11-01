import 'package:flutter_test/flutter_test.dart';
import 'package:app_serveur_flutter/features/robot/data/mock_robot_repository.dart';
import 'package:app_serveur_flutter/features/robot/domain/payment_status.dart';
import 'package:app_serveur_flutter/features/robot/domain/robot_status.dart';
import 'package:app_serveur_flutter/features/robot/domain/slot_assignment.dart';
import 'package:app_serveur_flutter/features/tasks/data/mock_orders_repository.dart';
import 'package:app_serveur_flutter/features/tasks/data/mock_tasks_repository.dart';
import 'package:app_serveur_flutter/features/tasks/domain/pending_order.dart';
import 'package:app_serveur_flutter/features/tasks/domain/placement_option.dart';
import 'package:app_serveur_flutter/features/tasks/ui/task_wizard_controller.dart';

/// Simulation 1000x plus rapide : 1 s de démo = 1 ms de test.
const double _fast = 0.001;

PendingOrder _order(String id, String table, {PaymentMode pay = PaymentMode.none}) => PendingOrder(
      id: id,
      tableNumber: table,
      items: const ['1x Café'],
      totalPrice: 3,
      initialPaymentMode: pay,
      createdAt: DateTime(2026),
    );

const _p1A = PlacementChoice(floorId: 1, zoneKey: 'A');
const _p1B = PlacementChoice(floorId: 1, zoneKey: 'B');
const _p2A = PlacementChoice(floorId: 2, zoneKey: 'A');

void main() {
  late MockRobotRepository robot;
  late TaskWizardController wizard;

  setUp(() {
    robot = MockRobotRepository(speed: _fast);
    wizard = TaskWizardController(
      ordersRepo: MockOrdersRepository(),
      tasksRepo: MockTasksRepository(robot),
      robotRepo: robot,
    );
  });

  tearDown(() {
    wizard.dispose();
    robot.dispose();
  });

  group('Sélection multiple et liste partie -> table', () {
    test('On peut choisir et retirer plusieurs parties', () {
      wizard.togglePlacement(_p1A);
      wizard.togglePlacement(_p2A);
      expect(wizard.state.selectedPlacements, [_p1A, _p2A]);
      wizard.togglePlacement(_p1A);
      expect(wizard.state.selectedPlacements, [_p2A]);
    });

    test('« Choisir pour moi » remplit les meilleures parties', () {
      final added = wizard.autoSelect(robot.currentState, wanted: 3);
      expect(added, 3);
      expect(wizard.state.selectedPlacements.map((p) => p.shortCode), ['1A', '1B', '2A']);
    });

    test('Chaque table touchée va sur la partie suivante, sans doublon', () {
      wizard.togglePlacement(_p1A);
      wizard.togglePlacement(_p1B);
      final t4 = _order('#1', 'Table 4');
      final t7 = _order('#2', 'Table 7');

      wizard.assignOrder(t4);
      expect(wizard.state.assignments[_p1A], t4);
      expect(wizard.state.targetPlacement, _p1B);

      wizard.assignOrder(t7);
      expect(wizard.state.assignments[_p1B], t7);
      expect(wizard.state.allAssigned, isTrue);

      // Toucher à nouveau la table 4 la retire (elle libère 1A).
      wizard.assignOrder(t4);
      expect(wizard.state.assignments.containsKey(_p1A), isFalse);
      expect(wizard.state.targetPlacement, _p1A);
    });

    test('Une même table ne peut pas être sur deux parties', () {
      wizard.togglePlacement(_p1A);
      wizard.togglePlacement(_p1B);
      final t4 = _order('#1', 'Table 4');
      wizard.assignOrder(t4); // -> 1A
      wizard.setActivePlacement(_p1B);
      wizard.assignOrder(t4); // déplacée vers 1B
      expect(wizard.state.assignments.length, 1);
      expect(wizard.state.assignments[_p1B], t4);
    });

    test('Le TPE est repris de la commande et modifiable', () {
      wizard.togglePlacement(_p1A);
      final o = _order('#1', 'Table 4', pay: PaymentMode.tpe);
      wizard.assignOrder(o);
      expect(wizard.state.requests.single.withTpe, isTrue);
      wizard.setPaymentMode(o, PaymentMode.none);
      expect(wizard.state.requests.single.withTpe, isFalse);
    });
  });

  group('Envoi unique au robot', () {
    void prepare() {
      wizard.togglePlacement(_p1A);
      wizard.togglePlacement(_p1B);
      wizard.assignOrder(_order('#CMD-201', 'Table 4', pay: PaymentMode.tpe));
      wizard.assignOrder(_order('#CMD-202', 'Table 7'));
      wizard.nextStep();
      wizard.nextStep();
    }

    test('Toutes les commandes partent en UNE opération', () async {
      prepare();
      final result = await wizard.submit();
      expect(result, isNotNull);
      expect(result!.batch.tasks.length, 2);
      expect(result.batch.tasks.map((t) => t.tableNumber), ['Table 4', 'Table 7']);
      expect(result.batch.tasks.first.paymentStatus, PaymentStatus.tpePending);

      final state = robot.currentState;
      final f1 = state.floors.firstWhere((f) => f.id == 1);
      expect(f1.zoneA.tableNumber, 'Table 4');
      expect(f1.zoneA.paymentStatus, PaymentStatus.tpePending);
      expect(f1.zoneB.tableNumber, 'Table 7');
      expect(state.status, RobotStatus.delivering);
    });

    test('Double envoi bloqué', () async {
      prepare();
      final results = await Future.wait([wizard.submit(), wizard.submit()]);
      expect(results.whereType<SubmitResult>().length, 1);
      expect(await wizard.submit(), isNull); // déjà envoyé
      expect(wizard.state.hasSubmitted, isTrue);
    });

    test('Re-vérification : partie prise entre-temps -> retour au Plateau', () async {
      prepare();
      // Un collègue vient d'occuper 1B.
      await robot.assignOrders(
        const [
          SlotAssignment(
              floorId: 1, zoneKey: 'B', orderId: '#AUTRE', tableNumber: 'Table 2', itemsSummary: '-'),
        ],
        deliverNow: false,
      );
      final result = await wizard.submit();
      expect(result, isNull);
      expect(wizard.state.currentStep, 0);
      expect(wizard.state.errorMessage, contains('1B'));
      expect(wizard.state.selectedPlacements, [_p1A]);
    });

    test('Re-vérification : robot devenu indisponible -> envoi refusé', () async {
      prepare();
      robot.simulateBatteryLevel(10);
      expect(await wizard.submit(), isNull);
      expect(wizard.state.errorMessage, contains('Batterie faible'));
      expect(wizard.state.hasSubmitted, isFalse);
    });
  });

  group('Paiement TPE en mémoire', () {
    test('Le robot attend « J\'ai terminé », puis passe à Payé et repart', () async {
      wizard.togglePlacement(_p1A);
      wizard.togglePlacement(_p1B);
      wizard.assignOrder(_order('#1', 'Table 4', pay: PaymentMode.tpe));
      wizard.assignOrder(_order('#2', 'Table 7'));
      wizard.nextStep();
      wizard.nextStep();
      final result = (await wizard.submit())!;
      final tasks = MockTasksRepository(robot);
      final tpeTask = result.batch.tasks.first;

      // Avant l'arrivée : impossible de payer.
      expect(() => robot.markPaymentDone(tpeTask.id), throwsException);

      // Arrivée à la 1re table (11 s démo = 11 ms).
      await Future.delayed(const Duration(milliseconds: 40));
      var batch = robot.batch(result.batch.id)!;
      expect(batch.tasks.first.isAwaitingTpe, isTrue);
      // Le robot reste à la table : la 2e livraison n'est pas encore arrivée.
      await Future.delayed(const Duration(milliseconds: 30));
      batch = robot.batch(result.batch.id)!;
      expect(batch.tasks.last.isDelivered, isFalse);
      expect(robot.currentState.floors.firstWhere((f) => f.id == 1).zoneA.paymentStatus,
          PaymentStatus.tpePending);

      // Le client appuie sur « J'ai terminé ».
      final paid = await tasks.markPaymentDone(tpeTask.id);
      expect(paid.paymentStatus, PaymentStatus.tpePaid);
      expect(robot.lastAnnouncement, "C'est bon, paiement validé");
      expect(robot.currentState.floors.firstWhere((f) => f.id == 1).zoneA.paymentStatus,
          PaymentStatus.tpePaid);

      // Le robot repart et termine la tournée.
      await Future.delayed(const Duration(milliseconds: 60));
      batch = robot.batch(result.batch.id)!;
      expect(batch.isFinished, isTrue);
      expect(robot.currentState.freeSlotsCount, 6);
      expect(robot.currentState.status, RobotStatus.idle);
    });

    test('Garder pour plus tard : rien ne bouge avant l\'ordre de départ', () async {
      wizard.togglePlacement(_p1A);
      wizard.assignOrder(_order('#1', 'Table 4'));
      wizard.nextStep();
      wizard.nextStep();
      wizard.setDeliverNow(false);
      final result = (await wizard.submit())!;
      expect(result.batch.isStored, isTrue);
      expect(robot.currentState.storedOrdersCount, 1);

      await robot.dispatchStoredOrders();
      expect(robot.currentState.status, RobotStatus.delivering);
      await Future.delayed(const Duration(milliseconds: 40));
      expect(robot.batch(result.batch.id)!.isFinished, isTrue);
    });
  });
}
