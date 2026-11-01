import '../domain/robot_state.dart';
import '../domain/robot_status.dart';
import '../domain/slot_assignment.dart';

/// Interface du Repository Robot avec support du temps réel et de la simulation.
abstract class RobotRepository {
  /// Récupère l'état instantané du robot.
  /// Endpoint backend réel : GET /api/robot/status
  Future<RobotStateModel> getRobotStatus();

  /// Flux en temps réel des changements d'état du robot.
  /// Backend réel : WS /ws/robot
  Stream<RobotStateModel> watchRobotStatus();

  /// Range PLUSIEURS commandes en une seule opération (une par partie A/B).
  ///
  /// - [deliverNow] : `true` = le robot part tout de suite et fait la tournée
  ///   dans l'ordre de la liste ; `false` = commandes rangées, départ plus
  ///   tard via [dispatchStoredOrders].
  ///
  /// En HTTP, le backend met déjà à jour les parties lors de
  /// POST /api/robot/tasks/batch : cette méthode ne fait alors rien.
  Future<void> assignOrders(
    List<SlotAssignment> assignments, {
    required bool deliverNow,
  });

  /// Envoie le robot livrer toutes les commandes rangées.
  /// Endpoint backend réel : POST /api/robot/dispatch
  Future<void> dispatchStoredOrders();

  /// Libère une partie après livraison à table.
  Future<void> freeSlot({required int floorId, required String zoneKey});

  // --- MÉTHODES DE SIMULATION POUR TESTER TOUS LES CAS ---
  void simulateBatteryLevel(int percentage);
  void simulateOccupyAllSlots();
  void simulateHalfOccupied();
  void simulateFreeAllSlots();
  void simulateStatus(RobotStatus status);
  void simulateCharging(bool charging);
}
