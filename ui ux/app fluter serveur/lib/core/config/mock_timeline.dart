/// Chronologie partagée par les MOCKS (robot + livraisons) pour que l'écran
/// du robot et l'écran de suivi avancent exactement en même temps.
///
/// Une tournée : prise en charge -> le robot roule -> 1er arrêt -> arrêts
/// suivants (une table toutes les [perStop]).
class MockTimeline {
  MockTimeline._();

  static const Duration picking = Duration(seconds: 3);
  static const Duration rolling = Duration(seconds: 6);
  static const Duration firstArrival = Duration(seconds: 11);
  static const Duration perStop = Duration(seconds: 5);
  static const Duration dwellAtStop = Duration(seconds: 3);

  /// Après « Payé », la partie reste affichée un court instant puis se libère.
  static const Duration paidDisplay = Duration(milliseconds: 2500);
}
