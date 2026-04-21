class ConsumptionStatsModel {
  final double? consommationJour;
  final double? consommationSemaine;
  final double? consommationMois;
  final double? consommationMoyenneJour;
  final String? periode;

  ConsumptionStatsModel({
    this.consommationJour,
    this.consommationSemaine,
    this.consommationMois,
    this.consommationMoyenneJour,
    this.periode,
  });

  factory ConsumptionStatsModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionStatsModel(
      consommationJour: (json['consommationJour'] as num?)?.toDouble(),
      consommationSemaine: (json['consommationSemaine'] as num?)?.toDouble(),
      consommationMois: (json['consommationMois'] as num?)?.toDouble(),
      consommationMoyenneJour: (json['consommationMoyenneJour'] as num?)?.toDouble(),
      periode: json['periode']?.toString(),
    );
  }

  String get formattedConsommationJour =>
      consommationJour == null ? 'N/A' : '${consommationJour!.toStringAsFixed(2)} kWh';

  String get formattedConsommationSemaine =>
      consommationSemaine == null ? 'N/A' : '${consommationSemaine!.toStringAsFixed(2)} kWh';

  String get formattedConsommationMois =>
      consommationMois == null ? 'N/A' : '${consommationMois!.toStringAsFixed(2)} kWh';

  String get formattedConsommationMoyenneJour =>
      consommationMoyenneJour == null ? 'N/A' : '${consommationMoyenneJour!.toStringAsFixed(2)} kWh';

  Map<String, double>? get consommationParJour => const {};
  Map<String, double>? get getConsommationParJourTriee => consommationParJour;

  double get creditRestant => 0.0;
  DateTime? get dateEstimationEpuisement => null;
  String get formattedCreditRestant => 'N/A';
  String get formattedDateEpuisement => 'N/A';
  bool get isCreditFaible => false;
  bool get isCreditCritique => false;
}
