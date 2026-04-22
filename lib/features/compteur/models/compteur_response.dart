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
    // Vérifier si la réponse a une structure avec un champ "data"
    final data = json['data'] ?? json;
    
    return CompteurResponse(
      id: data['id'],
      reference: data['reference'] ?? '',
      adresse: data['adresse'] ?? '',
      typeCompteur: data['typeCompteur'] ?? '',
      valeurActuelle: (data['valeurActuelle'] ?? 0).toDouble(),
      proprietaireNom: data['proprietaireNom'],
      proprietaireId: data['proprietaireId'],
      dateInitialisation: data['dateInitialisation'],
      actif: data['actif'] ?? true,
      dateCreation: data['dateCreation'],
    );
  }
}