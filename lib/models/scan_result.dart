class ScanResult {
  final String date;
  final String heure;
  final int nouvellesBouteilles;
  final String evenement;

  ScanResult({
    required this.date,
    required this.heure,
    required this.nouvellesBouteilles,
    required this.evenement,
  });

  factory ScanResult.fromQRString(String qrData) {
    final lines = qrData.split('\n');
    return ScanResult(
      date: lines[0].split(': ')[1],
      heure: lines[1].split(': ')[1],
      nouvellesBouteilles: int.parse(lines[2].split(': ')[1]),
      evenement: lines[4].split(': ')[1],
    );
  }

  static const double PRIX_BOUTEILLE = 0.100; // 100 millimes = 0.100 dinars

  double get gainCollecte {
    return nouvellesBouteilles * PRIX_BOUTEILLE;
  }
}
