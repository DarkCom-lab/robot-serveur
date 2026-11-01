import 'package:flutter_test/flutter_test.dart';
import 'package:app_serveur_flutter/features/robot/domain/floor_model.dart';
import 'package:app_serveur_flutter/features/robot/domain/robot_state.dart';
import 'package:app_serveur_flutter/features/tasks/domain/placement_option.dart';

void main() {
  group('Parties A/B et choix automatique', () {
    test('Un étage avec une seule partie occupée a 1 partie libre', () {
      const floor = RobotFloor(id: 2, zoneA: ZoneSlot(zoneKey: 'A', orderId: '#CMD-10'));
      expect(floor.freeCount, 1);
      expect(floor.isCompletelyFree, isFalse);
      expect(floor.hasNoFreeSlot, isFalse);
      expect(floor.zoneB.isFree, isTrue);
    });

    test('Libellés : A Gauche / B Droite, code court 2B', () {
      const c = PlacementChoice(floorId: 2, zoneKey: 'B');
      expect(c.displayLabel, 'Étage 2 • B Droite');
      expect(c.shortCode, '2B');
    });

    test('Auto : remplit d\'abord la partie restante d\'un étage entamé', () {
      final robot = RobotStateModel.initial().copyWith(floors: [
        const RobotFloor(id: 3),
        const RobotFloor(id: 2, zoneA: ZoneSlot(zoneKey: 'A', orderId: '#X')),
        const RobotFloor(id: 1),
      ]);
      expect(PlacementChoice.computeBestAutoPlacement(robot),
          const PlacementChoice(floorId: 2, zoneKey: 'B'));
    });

    test('Auto : sinon commence par l\'étage du bas (1A)', () {
      expect(PlacementChoice.computeBestAutoPlacement(RobotStateModel.initial()),
          const PlacementChoice(floorId: 1, zoneKey: 'A'));
    });

    test('Auto : robot sans partie libre -> aucun choix', () {
      ZoneSlot busy(String k) => ZoneSlot(zoneKey: k, orderId: '#$k');
      final robot = RobotStateModel.initial().copyWith(floors: [
        for (final id in [3, 2, 1]) RobotFloor(id: id, zoneA: busy('A'), zoneB: busy('B')),
      ]);
      expect(PlacementChoice.computeBestAutoPlacement(robot), isNull);
      expect(PlacementChoice.computeBestAutoPlacements(robot, 3), isEmpty);
    });

    test('Auto multiple : 3 parties dans le bon ordre (1A, 1B, 2A)', () {
      final list = PlacementChoice.computeBestAutoPlacements(RobotStateModel.initial(), 3);
      expect(list.map((c) => c.shortCode).toList(), ['1A', '1B', '2A']);
    });

    test('Auto multiple : garde les parties déjà choisies et ne les répète pas', () {
      final list = PlacementChoice.computeBestAutoPlacements(
        RobotStateModel.initial(),
        2,
        alreadyChosen: const [PlacementChoice(floorId: 1, zoneKey: 'A')],
      );
      expect(list.map((c) => c.shortCode).toList(), ['1B', '2A']);
    });

    test('Auto multiple : ne dépasse jamais le nombre de parties libres', () {
      final robot = RobotStateModel.initial().copyWith(floors: [
        const RobotFloor(id: 3),
        const RobotFloor(
            id: 2,
            zoneA: ZoneSlot(zoneKey: 'A', orderId: '#1'),
            zoneB: ZoneSlot(zoneKey: 'B', orderId: '#2')),
        const RobotFloor(id: 1, zoneA: ZoneSlot(zoneKey: 'A', orderId: '#3')),
      ]);
      final list = PlacementChoice.computeBestAutoPlacements(robot, 6);
      expect(list.map((c) => c.shortCode).toList(), ['1B', '3A', '3B']);
    });

    test('withSlot remplace uniquement la partie visée', () {
      const floor = RobotFloor(id: 3);
      final next = floor.withSlot('B', const ZoneSlot(zoneKey: 'B', orderId: '#1'));
      expect(next.zoneA.isFree, isTrue);
      expect(next.zoneB.isOccupied, isTrue);
    });
  });
}
