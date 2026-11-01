import '../../robot/domain/floor_model.dart';
import '../../robot/domain/robot_state.dart';

/// Emplacement sur le robot : un étage (1-3) + une partie A (gauche) / B (droite).
/// Les 3 étages sont identiques : 6 emplacements possibles au total.
class PlacementChoice {
  final int floorId; // 1, 2 ou 3
  final String zoneKey; // 'A' = gauche, 'B' = droite

  const PlacementChoice({required this.floorId, required this.zoneKey});

  String get zoneLabel => zoneKey == 'A' ? 'Gauche' : 'Droite';

  /// Ex : "Étage 2 • A Gauche"
  String get displayLabel => 'Étage $floorId • $zoneKey $zoneLabel';

  /// Ex : "2A" (affiché dans les pastilles).
  String get shortCode => '$floorId$zoneKey';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementChoice && floorId == other.floorId && zoneKey == other.zoneKey;

  @override
  int get hashCode => Object.hash(floorId, zoneKey);

  @override
  String toString() => shortCode;

  /// Choix automatique de la meilleure partie libre.
  ///
  /// 1. On remplit d'abord un étage déjà entamé (une partie libre, l'autre
  ///    occupée) : les autres étages restent entièrement libres.
  /// 2. Sinon on prend un étage vide en partant du BAS (robot plus stable).
  /// Retourne `null` si aucune partie n'est libre.
  static PlacementChoice? computeBestAutoPlacement(RobotStateModel robot) {
    final bottomUp = List.of(robot.floors)..sort((a, b) => a.id.compareTo(b.id));

    for (final floor in bottomUp) {
      if (floor.freeCount == 1) {
        return PlacementChoice(floorId: floor.id, zoneKey: floor.zoneA.isFree ? 'A' : 'B');
      }
    }
    for (final floor in bottomUp) {
      if (floor.isCompletelyFree) {
        return PlacementChoice(floorId: floor.id, zoneKey: 'A');
      }
    }
    return null;
  }

  /// Remplit automatiquement jusqu'à [count] parties libres, dans le meilleur
  /// ordre (même règle que [computeBestAutoPlacement], répétée).
  /// Les parties de [alreadyChosen] sont considérées comme prises.
  static List<PlacementChoice> computeBestAutoPlacements(
    RobotStateModel robot,
    int count, {
    Iterable<PlacementChoice> alreadyChosen = const [],
  }) {
    var simulated = robot;
    for (final c in alreadyChosen) {
      simulated = _reserve(simulated, c);
    }
    final result = <PlacementChoice>[];
    while (result.length < count) {
      final next = computeBestAutoPlacement(simulated);
      if (next == null) break;
      result.add(next);
      simulated = _reserve(simulated, next);
    }
    return result;
  }

  static RobotStateModel _reserve(RobotStateModel robot, PlacementChoice c) {
    final floors = robot.floors
        .map((f) => f.id == c.floorId
            ? f.withSlot(c.zoneKey, ZoneSlot(zoneKey: c.zoneKey, orderId: '_reserved'))
            : f)
        .toList();
    return robot.copyWith(floors: floors);
  }

  /// Toutes les parties libres du robot (haut -> bas, A puis B).
  static List<PlacementChoice> freePlacements(RobotStateModel robot) => [
        for (final f in robot.floorsTopDown)
          for (final s in f.slots)
            if (s.isFree) PlacementChoice(floorId: f.id, zoneKey: s.zoneKey),
      ];
}
