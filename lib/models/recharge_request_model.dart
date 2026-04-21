// RechargeRequestModel - Aligné sur RechargeRequestDTO du backend Spring Boot
class RechargeRequestModel {
  final int compteurId;
  final double montant;
  final String? codeRecharge;

  RechargeRequestModel({
    required this.compteurId,
    required this.montant,
    this.codeRecharge,
  });

  // Convertir l'objet en JSON pour l'envoi au backend
  Map<String, dynamic> toJson() {
    return {
      'compteurId': compteurId,
      'montant': montant,
      'codeRecharge': codeRecharge,
    };
  }

  // Validation
  bool get isValid {
    return compteurId > 0 && montant > 0.0;
  }

  @override
  String toString() {
    return 'RechargeRequestModel{compteurId: $compteurId, montant: $montant FCFA, codeRecharge: $codeRecharge}';
  }
}
