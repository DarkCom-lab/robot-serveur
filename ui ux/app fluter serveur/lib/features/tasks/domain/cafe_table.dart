/// Une table du café sur le plan. Position en fractions (0.0 à 1.0)
/// de la largeur / hauteur du plan.
class CafeTable {
  final String label; // Doit correspondre à PendingOrder.tableNumber
  final double x;
  final double y;

  const CafeTable({required this.label, required this.x, required this.y});
}

/// Plan du café (à adapter au vrai plan de la salle).
class CafeLayout {
  CafeLayout._();

  static const List<CafeTable> tables = [
    CafeTable(label: 'Table 1', x: 0.16, y: 0.22),
    CafeTable(label: 'Table 2', x: 0.40, y: 0.22),
    CafeTable(label: 'Table 3', x: 0.64, y: 0.22),
    CafeTable(label: 'Table 4', x: 0.88, y: 0.22),
    CafeTable(label: 'Table 5', x: 0.16, y: 0.52),
    CafeTable(label: 'Table 6', x: 0.40, y: 0.52),
    CafeTable(label: 'Table 7', x: 0.64, y: 0.52),
    CafeTable(label: 'Table 8', x: 0.88, y: 0.52),
    CafeTable(label: 'Table 9', x: 0.28, y: 0.82),
    CafeTable(label: 'Table 10', x: 0.52, y: 0.82),
  ];

  /// Numéro court affiché dans la pastille ("Table 10" -> "10").
  static String shortLabel(String label) => label.replaceFirst('Table ', '');
}
