class CompteurResponse {
  final int id;
  final String reference;
  final String adresse;
  final String typeCompteur;
  final double valeurActuelle;
  final String? proprietaireNom;
  final int? proprietaireId;
  final String? dateInitialisation;
  final bool actif;
  final String? dateCreation;

  CompteurResponse({
    required this.id,
    required this.reference,
    required this.adresse,
    required this.typeCompteur,
    required this.valeurActuelle,
    this.proprietaireNom,
    this.proprietaireId,
    this.dateInitialisation,
    required this.actif,
    this.dateCreation,
  });

  factory CompteurResponse.fromJson(Map<String, dynamic> json) {
    return CompteurResponse(
      id: json['id'],
      reference: json['reference'] ?? '',
      adresse: json['adresse'] ?? '',
      typeCompteur: json['typeCompteur'] ?? '',
      valeurActuelle: (json['valeurActuelle'] ?? 0).toDouble(),
      proprietaireNom: json['proprietaireNom'],
      proprietaireId: json['proprietaireId'],
      dateInitialisation: json['dateInitialisation'],
      actif: json['actif'] ?? true,
      dateCreation: json['dateCreation'],
    );
  }
}