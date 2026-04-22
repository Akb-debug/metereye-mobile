import 'type_compteur.dart';

class CreateCompteurRequest {
  final String reference;
  final String adresse;
  final TypeCompteur typeCompteur;
  final double valeurInitiale;

  CreateCompteurRequest({
    required this.reference,
    required this.adresse,
    required this.typeCompteur,
    required this.valeurInitiale,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'adresse': adresse,
        'typeCompteur': typeCompteur.toApiValue(),
        'valeurInitiale': valeurInitiale,
      };
}