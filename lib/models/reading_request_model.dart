// ReadingRequestModel - Aligné sur ReleveRequestDTO du backend Spring Boot
class ReadingRequestModel {
  final int compteurId;
  final double valeur;
  final String? commentaire;

  ReadingRequestModel({
    required this.compteurId,
    required this.valeur,
    this.commentaire,
  });

  // Convertir l'objet en JSON pour l'envoi au backend
  Map<String, dynamic> toJson() {
    return {
      'compteurId': compteurId,
      'valeur': valeur,
      'commentaire': commentaire,
    };
  }

  // Validation
  bool get isValid {
    return compteurId > 0 && valeur >= 0.0;
  }

  @override
  String toString() {
    return 'ReadingRequestModel{compteurId: $compteurId, valeur: $valeur, commentaire: $commentaire}';
  }
}
