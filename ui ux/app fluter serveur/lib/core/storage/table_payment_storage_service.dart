import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/tasks/domain/cafe_table.dart';
import '../../features/tasks/domain/table_payment_state.dart';

/// Service de persistance locale pour le statut des paiements TPE des tables.
/// Survit aux redémarrages, déconnexions et rafraîchissements de l'application.
class TablePaymentStorageService {
  static const String _storageKey = 'cafe_tables_payment_status_v1';
  final SharedPreferences? _prefs;

  TablePaymentStorageService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Initialise un dictionnaire propre pour toutes les tables (Table 1 à Table 10).
  static Map<String, TablePaymentInfo> createDefaultTablePayments() {
    final now = DateTime.now();
    return {
      for (final table in CafeLayout.tables)
        table.label: TablePaymentInfo(
          tableNumber: table.label,
          status: TableTpeStatus.none,
          updatedAt: now,
        ),
    };
  }

  /// Charge l'état de toutes les tables depuis SharedPreferences.
  Future<Map<String, TablePaymentInfo>> loadTablePayments() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_storageKey);
    final result = createDefaultTablePayments();

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            final info = TablePaymentInfo.fromMap(entry.value as Map<String, dynamic>);
            result[entry.key] = info;
          }
        }
      } catch (e) {
        // En cas d'erreur de parsing, on garde le résultat par défaut
      }
    }
    return result;
  }

  /// Enregistre l'ensemble des statuts de paiement.
  Future<void> saveTablePayments(Map<String, TablePaymentInfo> payments) async {
    final prefs = await _getPrefs();
    final map = payments.map((k, v) => MapEntry(k, v.toMap()));
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  /// Met à jour une seule table.
  Future<void> saveSinglePayment(TablePaymentInfo payment) async {
    final all = await loadTablePayments();
    all[payment.tableNumber] = payment;
    await saveTablePayments(all);
  }

  /// Efface les statuts sauvegardés (remise à zéro).
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }
}
