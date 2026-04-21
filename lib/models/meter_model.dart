class MeterModel {
  final int id;
  final String reference;
  final String adresse;
  final String typeCompteur;
  final double valeurActuelle;
  final String statut;
  final String? modeLectureConfigure;
  final String proprietaireEmail;
  final int proprietaireId;
  final DateTime? dateInitialisation;
  final bool actif;

  MeterModel({
    required this.id,
    required this.reference,
    required this.adresse,
    required this.typeCompteur,
    required this.valeurActuelle,
    required this.statut,
    this.modeLectureConfigure,
    required this.proprietaireEmail,
    required this.proprietaireId,
    this.dateInitialisation,
    required this.actif,
  });

  factory MeterModel.fromJson(Map<String, dynamic> json) {
    final proprietaire = json['proprietaire'] is Map<String, dynamic>
        ? json['proprietaire'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MeterModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reference: json['reference']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? '',
      typeCompteur: json['typeCompteur']?.toString() ?? '',
      valeurActuelle: (json['valeurActuelle'] as num?)?.toDouble() ?? 0.0,
      statut: json['statut']?.toString() ?? 'EN_ATTENTE_CONFIGURATION',
      modeLectureConfigure: json['modeLectureConfigure']?.toString(),
      proprietaireEmail: proprietaire['email']?.toString() ?? '',
      proprietaireId: (proprietaire['id'] as num?)?.toInt() ?? 0,
      dateInitialisation: json['dateInitialisation'] != null
          ? DateTime.tryParse(json['dateInitialisation'].toString())
          : null,
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'adresse': adresse,
      'typeCompteur': typeCompteur,
      'valeurActuelle': valeurActuelle,
      'statut': statut,
      'modeLectureConfigure': modeLectureConfigure,
      'proprietaireEmail': proprietaireEmail,
      'proprietaireId': proprietaireId,
      'dateInitialisation': dateInitialisation?.toIso8601String(),
      'actif': actif,
    };
  }

  bool get isCashPower => typeCompteur.toUpperCase() == 'CASH_POWER';
  bool get isClassique => typeCompteur.toUpperCase() == 'CLASSIQUE';
  bool get isPendingConfiguration =>
      statut.toUpperCase() == 'EN_ATTENTE_CONFIGURATION';
  bool get isManualMode => modeLectureConfigure?.toUpperCase() == 'MANUAL';
  bool get isEsp32CamMode => modeLectureConfigure?.toUpperCase() == 'ESP32_CAM';
  bool get isSensorMode => modeLectureConfigure?.toUpperCase() == 'SENSOR';

  String get formattedValeur {
    if (isCashPower) return '${valeurActuelle.toStringAsFixed(0)} FCFA';
    return '${valeurActuelle.toStringAsFixed(2)} kWh';
  }

  MeterModel copyWith({
    double? valeurActuelle,
    String? statut,
    String? modeLectureConfigure,
  }) {
    return MeterModel(
      id: id,
      reference: reference,
      adresse: adresse,
      typeCompteur: typeCompteur,
      valeurActuelle: valeurActuelle ?? this.valeurActuelle,
      statut: statut ?? this.statut,
      modeLectureConfigure: modeLectureConfigure ?? this.modeLectureConfigure,
      proprietaireEmail: proprietaireEmail,
      proprietaireId: proprietaireId,
      dateInitialisation: dateInitialisation,
      actif: actif,
    );
  }
}
