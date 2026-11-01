import 'floor_model.dart';
import 'payment_status.dart';
import 'robot_status.dart';
import '../../../core/config/app_config.dart';

/// Modèle complet de l'état du robot livreur à un instant T.
///
/// Le robot a 3 étages IDENTIQUES, chacun coupé en 2 parties :
/// A (gauche) et B (droite), soit 6 parties au total.
class RobotStateModel {
  final String robotId;
  final RobotStatus status;
  final int batteryPercentage;
  final bool isCharging;
  final List<RobotFloor> floors; // 3 étages
  /// Opération (lot de livraisons) en cours, si le robot fait une tournée.
  final String? activeTaskId;
  final String? activeDestinationTable;
  final DateTime lastUpdated;

  const RobotStateModel({
    required this.robotId,
    required this.status,
    required this.batteryPercentage,
    required this.isCharging,
    required this.floors,
    this.activeTaskId,
    this.activeDestinationTable,
    required this.lastUpdated,
  });

  static const int totalSlots = 6;

  /// Étages triés du haut (3) vers le bas (1), comme sur le robot réel.
  List<RobotFloor> get floorsTopDown =>
      List<RobotFloor>.from(floors)..sort((a, b) => b.id.compareTo(a.id));

  /// Nombre de parties libres (sur 6).
  int get freeSlotsCount => floors.fold(0, (sum, f) => sum + f.freeCount);

  /// Nombre de parties occupées (sur 6).
  int get occupiedSlotsCount => totalSlots - freeSlotsCount;

  /// Nombre de commandes rangées dans le robot qui attendent son départ.
  int get storedOrdersCount => floors
      .expand((f) => f.slots)
      .where((s) => s.isOccupied && s.isStored)
      .length;

  /// Aucune des 6 parties n'est libre.
  bool get hasNoFreeSlot => freeSlotsCount == 0;

  /// Commandes dont le paiement TPE est en mémoire (pas encore payé).
  int get tpePendingCount => floors
      .expand((f) => f.slots)
      .where((s) => s.isOccupied && s.paymentStatus == PaymentStatus.tpePending)
      .length;

  /// Le niveau de batterie est-il inférieur au seuil configurable ?
  bool get isLowBattery => batteryPercentage < AppConfig.lowBatteryThreshold;

  /// Le robot peut-il recevoir de nouvelles commandes ?
  bool get canAcceptNewTask {
    if (!status.isOperational) return false;
    if (isLowBattery) return false;
    if (hasNoFreeSlot) return false;
    return true;
  }

  /// Explication claire si le robot ne peut pas prendre de commande.
  String? get disabledReason {
    if (status == RobotStatus.offline) {
      return "Le robot est hors ligne, vérifiez la connexion.";
    }
    if (status == RobotStatus.charging) {
      return "Le robot est en charge sur sa base.";
    }
    if (status == RobotStatus.error) {
      return "Le robot est en incident technique.";
    }
    if (status == RobotStatus.returning) {
      return "Le robot retourne à la base, patientez.";
    }
    if (isLowBattery) {
      return "Batterie faible ($batteryPercentage%), le robot doit se recharger.";
    }
    if (hasNoFreeSlot) {
      return "Les 6 parties du robot sont occupées. Attendez qu'il termine ses livraisons.";
    }
    return null;
  }

  /// Robot neuf : 3 étages identiques (A + B) vides, batterie à 88 %.
  factory RobotStateModel.initial() {
    return RobotStateModel(
      robotId: 'ROBOT-01',
      status: RobotStatus.idle,
      batteryPercentage: 88,
      isCharging: false,
      floors: const [
        RobotFloor(id: 3),
        RobotFloor(id: 2),
        RobotFloor(id: 1),
      ],
      lastUpdated: DateTime.now(),
    );
  }

  RobotStateModel copyWith({
    String? robotId,
    RobotStatus? status,
    int? batteryPercentage,
    bool? isCharging,
    List<RobotFloor>? floors,
    String? activeTaskId,
    String? activeDestinationTable,
    DateTime? lastUpdated,
    bool clearActiveTask = false,
  }) {
    return RobotStateModel(
      robotId: robotId ?? this.robotId,
      status: status ?? this.status,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      isCharging: isCharging ?? this.isCharging,
      floors: floors ?? this.floors,
      activeTaskId: clearActiveTask ? null : (activeTaskId ?? this.activeTaskId),
      activeDestinationTable:
          clearActiveTask ? null : (activeDestinationTable ?? this.activeDestinationTable),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'robotId': robotId,
        'status': status.code,
        'batteryPercentage': batteryPercentage,
        'isCharging': isCharging,
        'floors': floors.map((f) => f.toJson()).toList(),
        'activeTaskId': activeTaskId,
        'activeDestinationTable': activeDestinationTable,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory RobotStateModel.fromJson(Map<String, dynamic> json) {
    return RobotStateModel(
      robotId: json['robotId'] as String? ?? 'ROBOT-01',
      status: RobotStatus.fromCode(json['status'] as String? ?? 'idle'),
      batteryPercentage: json['batteryPercentage'] as int? ?? 100,
      isCharging: json['isCharging'] as bool? ?? false,
      floors: (json['floors'] as List<dynamic>?)
              ?.map((f) => RobotFloor.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      activeTaskId: json['activeTaskId'] as String?,
      activeDestinationTable: json['activeDestinationTable'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
}
