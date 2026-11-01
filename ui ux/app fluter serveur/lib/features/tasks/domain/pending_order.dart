/// Mode de paiement sélectionné pour la commande.
enum PaymentMode {
  tpe('tpe', 'Paiement par TPE', 'Le serveur doit être appelé avec le TPE à la livraison'),
  none('none', 'Sans TPE', 'Cash ou commande déjà payée');

  final String code;
  final String label;
  final String description;

  const PaymentMode(this.code, this.label, this.description);

  static PaymentMode fromCode(String code) {
    return PaymentMode.values.firstWhere(
      (m) => m.code.toLowerCase() == code.toLowerCase(),
      orElse: () => PaymentMode.none,
    );
  }
}

/// Modèle d'une commande client en attente de livraison au bar/cuisine.
class PendingOrder {
  final String id; // Ex: '#CMD-201'
  final String tableNumber; // Ex: 'Table 4'
  final List<String> items;
  final double totalPrice;
  final PaymentMode initialPaymentMode;
  final DateTime createdAt;

  const PendingOrder({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.initialPaymentMode,
    required this.createdAt,
  });

  String get itemsSummary => items.join(', ');

  Duration get waitingDuration => DateTime.now().difference(createdAt);

  String get formattedWaitingDuration {
    final minutes = waitingDuration.inMinutes;
    if (minutes <= 0) return 'À l\'instant';
    return 'Il y a $minutes min';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableNumber': tableNumber,
        'items': items,
        'totalPrice': totalPrice,
        'initialPaymentMode': initialPaymentMode.code,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingOrder.fromJson(Map<String, dynamic> json) {
    return PendingOrder(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as String,
      items: List<String>.from(json['items'] as List),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      initialPaymentMode: PaymentMode.fromCode(json['initialPaymentMode'] as String? ?? 'none'),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
