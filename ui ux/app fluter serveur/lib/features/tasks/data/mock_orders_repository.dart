import 'dart:async';
import '../domain/pending_order.dart';
import 'orders_repository.dart';

/// Mock simulant la file de commandes en cuisine/bar du café.
/// Contient des commandes réalistes pour toutes les tables (1 à 10).
class MockOrdersRepository implements OrdersRepository {
  final List<PendingOrder> _orders = [
    PendingOrder(
      id: '#CMD-101',
      tableNumber: 'Table 1',
      items: ['1x Café Espresso', '1x Croissant Pur Beurre'],
      totalPrice: 5.20,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    PendingOrder(
      id: '#CMD-102',
      tableNumber: 'Table 2',
      items: ['2x Latte Macchiato Caramel', '2x Pain au Chocolat'],
      totalPrice: 15.00,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
    ),
    PendingOrder(
      id: '#CMD-103',
      tableNumber: 'Table 3',
      items: ['1x Thé Vert Jasmin', '1x Muffin Myrtille'],
      totalPrice: 7.80,
      initialPaymentMode: PaymentMode.tpe,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    PendingOrder(
      id: '#CMD-104',
      tableNumber: 'Table 4',
      items: ['2x Café Allongé', '1x Tartelette Citron Meringuée'],
      totalPrice: 11.50,
      initialPaymentMode: PaymentMode.tpe,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    PendingOrder(
      id: '#CMD-105',
      tableNumber: 'Table 5',
      items: ['1x Chocolat Chaud Maison', '1x Brioche Toastée'],
      totalPrice: 8.50,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    PendingOrder(
      id: '#CMD-106',
      tableNumber: 'Table 6',
      items: ['2x Flat White', '1x Cookie Pépites Chocolat'],
      totalPrice: 10.90,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
    PendingOrder(
      id: '#CMD-107',
      tableNumber: 'Table 7',
      items: ['1x Cappuccino Lait d\'Avoine', '1x Cookie Noisette'],
      totalPrice: 8.90,
      initialPaymentMode: PaymentMode.tpe,
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    PendingOrder(
      id: '#CMD-108',
      tableNumber: 'Table 8',
      items: ['1x Jus d\'Orange Pressé', '1x Granola Bowl Fruits'],
      totalPrice: 12.00,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    PendingOrder(
      id: '#CMD-109',
      tableNumber: 'Table 9',
      items: ['2x Espresso Double', '1x Canelé'],
      totalPrice: 9.40,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    PendingOrder(
      id: '#CMD-110',
      tableNumber: 'Table 10',
      items: ['1x Matcha Latte Glacé', '1x Cheesecake New-Yorkais'],
      totalPrice: 13.20,
      initialPaymentMode: PaymentMode.tpe,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
  ];

  @override
  Future<List<PendingOrder>> getPendingOrders() async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Tri par date d'arrivée croissante (les plus anciennes en premier - FIFO)
    final sorted = List<PendingOrder>.from(_orders)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  Future<void> removePendingOrder(String orderId) async {
    _orders.removeWhere((o) => o.id == orderId);
  }

  /// Récupère ou crée une commande à la volée pour une table donnée.
  PendingOrder getOrCreateForTable(String tableNumber) {
    for (final o in _orders) {
      if (o.tableNumber == tableNumber) return o;
    }
    final numStr = tableNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final newOrder = PendingOrder(
      id: '#CMD-GEN-$numStr',
      tableNumber: tableNumber,
      items: ['1x Boisson chaude', '1x Pâtisserie du jour'],
      totalPrice: 9.50,
      initialPaymentMode: PaymentMode.none,
      createdAt: DateTime.now(),
    );
    _orders.add(newOrder);
    return newOrder;
  }
}
