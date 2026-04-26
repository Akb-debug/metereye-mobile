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
      id: json['id'] as int,
      valeur: (json['valeur'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      consommationCalculee: (json['consommationCalculee'] as num).toDouble(),
      source: json['source'] as String,
      statut: json['statut'] as String,
      commentaire: json['commentaire'] as String?,
      imageUrl: json['imageUrl'] as String?,
      compteurId: json['compteurId'] as int,
      compteurReference: json['compteurReference'] as String,
      ocrConfidence: json['ocrConfidence'] as double?,
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