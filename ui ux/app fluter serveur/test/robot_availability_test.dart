import 'package:flutter_test/flutter_test.dart';
import 'package:app_serveur_flutter/features/robot/domain/floor_model.dart';
import 'package:app_serveur_flutter/features/robot/domain/payment_status.dart';
import 'package:app_serveur_flutter/features/robot/domain/robot_state.dart';
import 'package:app_serveur_flutter/features/robot/domain/robot_status.dart';

ZoneSlot _busy(String key, String id) => ZoneSlot(zoneKey: key, orderId: id, tableNumber: 'Table 1');

void main() {
  group('Disponibilité du robot (3 étages x 2 parties A/B)', () {
    test('Robot neuf : 6 parties libres, il accepte des commandes', () {
      final robot = RobotStateModel.initial();
      expect(robot.freeSlotsCount, 6);
      expect(robot.occupiedSlotsCount, 0);
      expect(robot.hasNoFreeSlot, isFalse);
      expect(robot.canAcceptNewTask, isTrue);
      expect(robot.disabledReason, isNull);
    });

    test('Une seule partie libre : le robot est encore LIBRE', () {
      final floors = [
        RobotFloor(id: 3, zoneA: _busy('A', '1'), zoneB: _busy('B', '2')),
        RobotFloor(id: 2, zoneA: _busy('A', '3'), zoneB: _busy('B', '4')),
        RobotFloor(id: 1, zoneA: _busy('A', '5')),
      ];
      final robot = RobotStateModel.initial().copyWith(floors: floors);
      expect(robot.freeSlotsCount, 1);
      expect(robot.canAcceptNewTask, isTrue);
    });

    test('6 parties occupées : NON LIBRE avec message clair', () {
      final floors = [
        RobotFloor(id: 3, zoneA: _busy('A', '1'), zoneB: _busy('B', '2')),
        RobotFloor(id: 2, zoneA: _busy('A', '3'), zoneB: _busy('B', '4')),
        RobotFloor(id: 1, zoneA: _busy('A', '5'), zoneB: _busy('B', '6')),
      ];
      final robot = RobotStateModel.initial().copyWith(floors: floors);
      expect(robot.hasNoFreeSlot, isTrue);
      expect(robot.canAcceptNewTask, isFalse);
      expect(robot.disabledReason, contains('6 parties'));
    });

    test('Batterie faible (< 20 %) : NON LIBRE', () {
      final robot = RobotStateModel.initial().copyWith(batteryPercentage: 15);
      expect(robot.isLowBattery, isTrue);
      expect(robot.canAcceptNewTask, isFalse);
      expect(robot.disabledReason, contains('Batterie faible (15%)'));
    });

    test('Hors ligne, en charge ou en erreur : NON LIBRE', () {
      final offline = RobotStateModel.initial().copyWith(status: RobotStatus.offline);
      expect(offline.canAcceptNewTask, isFalse);
      expect(offline.disabledReason, contains('hors ligne'));

      final charging = RobotStateModel.initial().copyWith(status: RobotStatus.charging);
      expect(charging.canAcceptNewTask, isFalse);
      expect(charging.disabledReason, contains('en charge'));

      final error = RobotStateModel.initial().copyWith(status: RobotStatus.error);
      expect(error.canAcceptNewTask, isFalse);
      expect(error.disabledReason, contains('incident'));
    });

    test('clearActiveTask efface bien la mission', () {
      final busy = RobotStateModel.initial()
          .copyWith(activeTaskId: 'OP-1', activeDestinationTable: 'Table 4');
      final done = busy.copyWith(clearActiveTask: true);
      expect(done.activeTaskId, isNull);
      expect(done.activeDestinationTable, isNull);
    });

    test('Les commandes rangées et les TPE en attente sont comptés', () {
      final floors = [
        const RobotFloor(id: 3),
        const RobotFloor(
          id: 2,
          zoneA: ZoneSlot(zoneKey: 'A', orderId: '#1', isStored: true),
          zoneB: ZoneSlot(zoneKey: 'B', orderId: '#2', paymentStatus: PaymentStatus.tpePending),
        ),
        const RobotFloor(
          id: 1,
          zoneA: ZoneSlot(zoneKey: 'A', orderId: '#3', paymentStatus: PaymentStatus.tpePaid),
        ),
      ];
      final robot = RobotStateModel.initial().copyWith(floors: floors);
      expect(robot.storedOrdersCount, 1);
      expect(robot.tpePendingCount, 1);
    });
  });

  group('Étage 1 : coupé en A et B comme les étages 2 et 3', () {
    test('Les 3 étages ont exactement 2 parties A et B', () {
      final robot = RobotStateModel.initial();
      expect(robot.floors.map((f) => f.id).toSet(), {1, 2, 3});
      for (final f in robot.floors) {
        expect(f.slots.map((s) => s.zoneKey).toList(), ['A', 'B']);
        expect(f.zoneA.label, 'Gauche');
        expect(f.zoneB.label, 'Droite');
      }
    });

    test('On peut occuper uniquement 1A, 1B reste libre', () {
      const floor1 = RobotFloor(id: 1, zoneA: ZoneSlot(zoneKey: 'A', orderId: '#X'));
      expect(floor1.zoneA.isOccupied, isTrue);
      expect(floor1.zoneB.isFree, isTrue);
      expect(floor1.freeCount, 1);
    });

    test('Le JSON de l\'étage 1 garde ses 2 parties', () {
      const floor1 = RobotFloor(
        id: 1,
        zoneB: ZoneSlot(zoneKey: 'B', orderId: '#9', paymentStatus: PaymentStatus.tpePending),
      );
      final back = RobotFloor.fromJson(floor1.toJson());
      expect(back.id, 1);
      expect(back.zoneA.isFree, isTrue);
      expect(back.zoneB.orderId, '#9');
      expect(back.zoneB.paymentStatus, PaymentStatus.tpePending);
    });
  });
}
