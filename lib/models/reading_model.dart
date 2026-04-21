class ReadingModel {
  final int id;
  final double valeur;
  final DateTime dateTime;
  final double? consommationCalculee;
  final String source;
  final String statut;
  final String? commentaire;
  final String? imageUrl;
  final int compteurId;
  final String compteurReference;

  ReadingModel({
    required this.id,
    required this.valeur,
    required this.dateTime,
    this.consommationCalculee,
    required this.source,
    required this.statut,
    this.commentaire,
    this.imageUrl,
    required this.compteurId,
    required this.compteurReference,
  });

  factory ReadingModel.fromJson(Map<String, dynamic> json) {
    final compteur = json['compteur'] is Map<String, dynamic>
        ? json['compteur'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ReadingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      valeur: (json['valeur'] as num?)?.toDouble() ?? 0.0,
      dateTime: DateTime.tryParse(json['dateTime']?.toString() ?? '') ?? DateTime.now(),
      consommationCalculee: (json['consommationCalculee'] as num?)?.toDouble(),
      source: json['source']?.toString() ?? 'MANUEL',
      statut: json['statut']?.toString() ?? 'VALIDE',
      commentaire: json['commentaire']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      compteurId: (compteur['id'] as num?)?.toInt() ?? 0,
      compteurReference: compteur['reference']?.toString() ?? '',
    );
  }

  String get formattedValeur => valeur.toStringAsFixed(2);

  String get formattedConsommation {
    if (consommationCalculee == null) return 'N/A';
    return '${consommationCalculee!.toStringAsFixed(2)} kWh';
  }

  String get formattedDate {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool get isManuel => source.toUpperCase() == 'MANUEL';
  bool get isEsp32Cam => source.toUpperCase() == 'ESP32_CAM';
  bool get isSensor => source.toUpperCase() == 'SENSOR';

  bool get isOcr => false;
  bool get isAutomatique => isEsp32Cam || isSensor;
  double? get valeurOcr => null;
  double? get confianceOcr => null;
  String get formattedConfianceOcr => 'N/A';
}
