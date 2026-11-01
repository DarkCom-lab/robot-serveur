import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../robot/domain/payment_status.dart';
import 'pending_order.dart';

/// Étapes de progression d'une livraison robot.
enum DeliveryStep {
  pending('Transmise', 'Le robot a reçu la commande', Icons.access_time_rounded),
  picking('Prise en charge', 'Le plateau est posé dans le robot', Icons.pan_tool_alt_rounded),
  delivering('En route', 'Le robot roule vers la table', Icons.navigation_rounded),
  delivered('Arrivée', 'Le robot est à la table du client', Icons.check_circle_rounded);

  final String label;
  final String description;
  final IconData icon;

  const DeliveryStep(this.label, this.description, this.icon);

  Color get color {
    switch (this) {
      case DeliveryStep.pending:
        return AppColors.primary;
      case DeliveryStep.picking:
        return AppColors.primaryLight;
      case DeliveryStep.delivering:
        return AppColors.statusDelivering;
      case DeliveryStep.delivered:
        return AppColors.statusIdle;
    }
  }

  static DeliveryStep fromName(String? name) => DeliveryStep.values.firstWhere(
        (s) => s.name == name,
        orElse: () => DeliveryStep.pending,
      );
}

/// Une livraison (une commande, une partie du robot, une table).
/// Les livraisons envoyées ensemble partagent le même [batchId].
class RobotTask {
  final String id;
  final String batchId;

  /// Ordre de passage dans la tournée (0 = première table).
  final int stopIndex;
  final String orderId;
  final String tableNumber;
  final int floorId;
  final String zoneKey; // 'A' (gauche) ou 'B' (droite)
  final PaymentStatus paymentStatus;
  final DeliveryStep currentStep;

  /// `true` tant que la commande est rangée et attend l'ordre de départ.
  final bool isStored;
  final DateTime createdAt;
  final DateTime? completedAt;

  const RobotTask({
    required this.id,
    required this.batchId,
    this.stopIndex = 0,
    required this.orderId,
    required this.tableNumber,
    required this.floorId,
    required this.zoneKey,
    this.paymentStatus = PaymentStatus.none,
    required this.currentStep,
    this.isStored = false,
    required this.createdAt,
    this.completedAt,
  });

  bool get isDelivered => currentStep == DeliveryStep.delivered;

  /// Le robot est à la table et le client n'a pas encore fini de payer.
  bool get isAwaitingTpe => isDelivered && paymentStatus == PaymentStatus.tpePending;

  /// Livraison finie : arrivée ET (sans TPE ou déjà payée).
  bool get isFinished => isDelivered && !isAwaitingTpe;

  PaymentMode get paymentMode => paymentStatus.usesTpe ? PaymentMode.tpe : PaymentMode.none;

  String get zoneLabel => zoneKey == 'A' ? 'Gauche' : 'Droite';

  /// Ex. « Étage 1 • A Gauche »
  String get locationLabel => 'Étage $floorId • $zoneKey $zoneLabel';

  /// Ex. « 1A »
  String get shortLocation => '$floorId$zoneKey';

  RobotTask copyWith({
    PaymentStatus? paymentStatus,
    DeliveryStep? currentStep,
    bool? isStored,
    DateTime? completedAt,
  }) {
    return RobotTask(
      id: id,
      batchId: batchId,
      stopIndex: stopIndex,
      orderId: orderId,
      tableNumber: tableNumber,
      floorId: floorId,
      zoneKey: zoneKey,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      currentStep: currentStep ?? this.currentStep,
      isStored: isStored ?? this.isStored,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batchId': batchId,
        'stopIndex': stopIndex,
        'orderId': orderId,
        'tableNumber': tableNumber,
        'floorId': floorId,
        'zoneKey': zoneKey,
        'paymentStatus': paymentStatus.code,
        'currentStep': currentStep.name,
        'isStored': isStored,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory RobotTask.fromJson(Map<String, dynamic> json) {
    final payment = json['paymentStatus'] != null
        ? PaymentStatus.fromCode(json['paymentStatus'] as String?)
        : PaymentStatus.initial(withTpe: json['paymentMode'] == 'tpe');
    return RobotTask(
      id: json['id'] as String,
      batchId: json['batchId'] as String? ?? json['id'] as String,
      stopIndex: json['stopIndex'] as int? ?? 0,
      orderId: json['orderId'] as String,
      tableNumber: json['tableNumber'] as String,
      floorId: (json['floorId'] ?? json['floor']) as int,
      zoneKey: ((json['zoneKey'] ?? json['zone']) as String).toUpperCase(),
      paymentStatus: payment,
      currentStep: DeliveryStep.fromName(json['currentStep'] as String?),
      isStored: json['isStored'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }
}

/// Une opération = plusieurs commandes envoyées au robot en une fois.
class DeliveryBatch {
  final String id;
  final List<RobotTask> tasks; // triées par ordre de passage

  DeliveryBatch({required this.id, required List<RobotTask> tasks})
      : tasks = List.unmodifiable(
            List<RobotTask>.from(tasks)..sort((a, b) => a.stopIndex.compareTo(b.stopIndex)));

  bool get isStored => tasks.isNotEmpty && tasks.every((t) => t.isStored);
  bool get isFinished => tasks.isNotEmpty && tasks.every((t) => t.isFinished);
  int get finishedCount => tasks.where((t) => t.isFinished).length;

  /// Livraison sur laquelle le robot travaille en ce moment.
  RobotTask? get currentStop {
    for (final t in tasks) {
      if (!t.isFinished) return t;
    }
    return null;
  }

  /// Étape globale de la tournée.
  DeliveryStep get overallStep {
    if (tasks.isEmpty) return DeliveryStep.pending;
    if (isFinished) return DeliveryStep.delivered;
    final current = currentStop!;
    if (current.isDelivered) return DeliveryStep.delivered;
    return current.currentStep;
  }

  Map<String, dynamic> toJson() => {
        'batchId': id,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory DeliveryBatch.fromJson(Map<String, dynamic> json) => DeliveryBatch(
        id: json['batchId'] as String,
        tasks: (json['tasks'] as List<dynamic>? ?? [])
            .map((t) => RobotTask.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
