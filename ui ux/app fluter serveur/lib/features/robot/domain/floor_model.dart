import 'payment_status.dart';

/// Une des 2 parties d'un étage : A (gauche) ou B (droite).
///
/// Les 3 étages sont IDENTIQUES : chacun a toujours une partie A et une
/// partie B (6 parties au total). Les clés 'A' / 'B' sont celles de l'API.
class ZoneSlot {
  final String zoneKey; // 'A' = gauche, 'B' = droite
  final String? orderId;
  final String? taskId;
  final String? tableNumber;
  final String? itemsSummary;

  /// Paiement mémorisé par le robot pour cette commande.
  final PaymentStatus paymentStatus;

  /// La commande est rangée dans le robot mais il ne part que plus tard.
  final bool isStored;

  const ZoneSlot({
    required this.zoneKey,
    this.orderId,
    this.taskId,
    this.tableNumber,
    this.itemsSummary,
    this.paymentStatus = PaymentStatus.none,
    this.isStored = false,
  });

  bool get isOccupied => orderId != null && orderId!.isNotEmpty;
  bool get isFree => !isOccupied;

  /// Le client paie par TPE (en attente ou déjà payé).
  bool get needsTpe => paymentStatus.usesTpe;

  /// Nom lisible : "Gauche" / "Droite".
  String get label => zoneKey == 'A' ? 'Gauche' : 'Droite';

  /// Nom avec la lettre : "A • Gauche".
  String get fullLabel => '$zoneKey • $label';

  ZoneSlot copyWith({PaymentStatus? paymentStatus, bool? isStored}) => ZoneSlot(
        zoneKey: zoneKey,
        orderId: orderId,
        taskId: taskId,
        tableNumber: tableNumber,
        itemsSummary: itemsSummary,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        isStored: isStored ?? this.isStored,
      );

  Map<String, dynamic> toJson() => {
        'zoneKey': zoneKey,
        'orderId': orderId,
        'taskId': taskId,
        'tableNumber': tableNumber,
        'itemsSummary': itemsSummary,
        'paymentStatus': paymentStatus.code,
        'isStored': isStored,
      };

  factory ZoneSlot.fromJson(Map<String, dynamic> json, String fallbackKey) {
    // Compatibilité : un ancien backend envoyait seulement needsTpe: bool.
    final status = json['paymentStatus'] != null
        ? PaymentStatus.fromCode(json['paymentStatus'] as String?)
        : PaymentStatus.initial(withTpe: json['needsTpe'] as bool? ?? false);
    return ZoneSlot(
      zoneKey: json['zoneKey'] as String? ?? fallbackKey,
      orderId: json['orderId'] as String?,
      taskId: json['taskId'] as String?,
      tableNumber: json['tableNumber'] as String?,
      itemsSummary: json['itemsSummary'] as String?,
      paymentStatus: status,
      isStored: json['isStored'] as bool? ?? false,
    );
  }
}

/// Un des 3 étages du robot (1 = bas, 3 = haut).
/// Tous les étages, y compris l'étage 1, sont coupés en 2 parties A et B.
class RobotFloor {
  final int id;
  final ZoneSlot zoneA; // Gauche
  final ZoneSlot zoneB; // Droite

  const RobotFloor({
    required this.id,
    this.zoneA = const ZoneSlot(zoneKey: 'A'),
    this.zoneB = const ZoneSlot(zoneKey: 'B'),
  });

  String get label => 'Étage $id';

  List<ZoneSlot> get slots => [zoneA, zoneB];

  ZoneSlot slotByKey(String key) => key == 'A' ? zoneA : zoneB;

  int get freeCount => slots.where((s) => s.isFree).length;
  int get occupiedCount => 2 - freeCount;

  bool get isCompletelyFree => freeCount == 2;
  bool get hasNoFreeSlot => freeCount == 0;
  bool get hasAnyAvailableSlot => freeCount > 0;

  /// Remplace une partie (clé 'A' ou 'B') par une autre valeur.
  RobotFloor withSlot(String key, ZoneSlot slot) => key == 'A'
      ? RobotFloor(id: id, zoneA: slot, zoneB: zoneB)
      : RobotFloor(id: id, zoneA: zoneA, zoneB: slot);

  Map<String, dynamic> toJson() => {
        'id': id,
        'zoneA': zoneA.toJson(),
        'zoneB': zoneB.toJson(),
      };

  factory RobotFloor.fromJson(Map<String, dynamic> json) => RobotFloor(
        id: json['id'] as int? ?? 1,
        zoneA: json['zoneA'] is Map<String, dynamic>
            ? ZoneSlot.fromJson(json['zoneA'] as Map<String, dynamic>, 'A')
            : const ZoneSlot(zoneKey: 'A'),
        zoneB: json['zoneB'] is Map<String, dynamic>
            ? ZoneSlot.fromJson(json['zoneB'] as Map<String, dynamic>, 'B')
            : const ZoneSlot(zoneKey: 'B'),
      );
}
