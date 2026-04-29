class Releve {
  final int id;
  final double valeur;
  final DateTime dateTime;
  final double consommationCalculee;
  final String source; // MANUEL, ESP32_CAM, SENSOR
  final String statut; // VALIDE, ERREUR, EN_ATTENTE
  final String? commentaire;
  final String? imageUrl;
  final int compteurId;
  final String compteurReference;
  final double? ocrConfidence;

  Releve({
    required this.id,
    required this.valeur,
    required this.dateTime,
    required this.consommationCalculee,
    required this.source,
    required this.statut,
    this.commentaire,
    this.imageUrl,
    required this.compteurId,
    required this.compteurReference,
    this.ocrConfidence,
  });

  factory Releve.fromJson(Map<String, dynamic> json) {
    return Releve(
      id: (json['id'] as num?)?.toInt() ?? 0,
      valeur: ((json['valeur'] ?? json['value']) as num?)?.toDouble() ?? 0.0,
      dateTime: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      consommationCalculee:
          (json['consommationCalculee'] as num?)?.toDouble() ?? 0.0,
      source: json['source']?.toString() ?? 'MANUEL',
      statut: json['statut']?.toString() ?? 'VALIDE',
      commentaire: (json['commentaire'] ?? json['comment'])?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      compteurId: ((json['compteurId'] ?? json['meterId']) as num?)?.toInt() ?? 0,
      compteurReference: (json['compteurReference'] ?? json['meterReference'] ?? '')
          .toString(),
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'valeur': valeur,
    'commentaire': commentaire,
  };
}

class CreateReleveRequest {
  final int compteurId;
  final double valeur;
  final String? commentaire;

  CreateReleveRequest({
    required this.compteurId,
    required this.valeur,
    this.commentaire,
  });

  Map<String, dynamic> toJson() => {
    'compteurId': compteurId,
    'valeur': valeur,
    if (commentaire != null) 'commentaire': commentaire,
  };
}