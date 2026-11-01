import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Statut de paiement TPE pour chaque table du café.
enum TableTpeStatus {
  none,    // Aucun paiement en cours / libre
  pending, // TPE demandé / en attente de règlement (Orange / Rouge)
  paid,    // Paiement TPE validé / reçu (Vert)
}

extension TableTpeStatusX on TableTpeStatus {
  String get label {
    switch (this) {
      case TableTpeStatus.none:
        return 'Aucun paiement';
      case TableTpeStatus.pending:
        return 'TPE Non payé';
      case TableTpeStatus.paid:
        return 'Payé';
    }
  }

  Color get color {
    switch (this) {
      case TableTpeStatus.none:
        return AppColors.textMuted;
      case TableTpeStatus.pending:
        return AppColors.paymentTpe; // Orange vif
      case TableTpeStatus.paid:
        return AppColors.statusIdle; // Vert franc
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TableTpeStatus.none:
        return AppColors.surfaceElevated;
      case TableTpeStatus.pending:
        return AppColors.paymentTpe.withOpacity(0.18);
      case TableTpeStatus.paid:
        return AppColors.statusIdle.withOpacity(0.18);
    }
  }

  IconData get icon {
    switch (this) {
      case TableTpeStatus.none:
        return Icons.table_bar_outlined;
      case TableTpeStatus.pending:
        return Icons.contactless_rounded;
      case TableTpeStatus.paid:
        return Icons.check_circle_rounded;
    }
  }
}

/// Informations de paiement associées à une table.
class TablePaymentInfo {
  final String tableNumber; // "Table 1" à "Table 10"
  final TableTpeStatus status;
  final double? amount;
  final String? orderId;
  final DateTime updatedAt;

  const TablePaymentInfo({
    required this.tableNumber,
    this.status = TableTpeStatus.none,
    this.amount,
    this.orderId,
    required this.updatedAt,
  });

  TablePaymentInfo copyWith({
    String? tableNumber,
    TableTpeStatus? status,
    double? amount,
    String? orderId,
    DateTime? updatedAt,
  }) {
    return TablePaymentInfo(
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      orderId: orderId ?? this.orderId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'status': status.name,
        'amount': amount,
        'orderId': orderId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TablePaymentInfo.fromMap(Map<String, dynamic> map) {
    return TablePaymentInfo(
      tableNumber: map['tableNumber'] as String,
      status: TableTpeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableTpeStatus.none,
      ),
      amount: (map['amount'] as num?)?.toDouble(),
      orderId: map['orderId'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory TablePaymentInfo.fromJson(String source) =>
      TablePaymentInfo.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
