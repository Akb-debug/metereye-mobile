class ConsumptionResponseModel {
  final double consommationTotale;
  final double consommationJournaliere;
  final int nombreJours;
  final String debut;
  final String fin;

  ConsumptionResponseModel({
    required this.consommationTotale,
    required this.consommationJournaliere,
    required this.nombreJours,
    required this.debut,
    required this.fin,
  });

  factory ConsumptionResponseModel.fromJson(Map<String, dynamic> json) {
    final periode = json['periode'] is Map<String, dynamic>
        ? json['periode'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ConsumptionResponseModel(
      consommationTotale: (json['consommationTotale'] as num?)?.toDouble() ?? 0.0,
      consommationJournaliere: (json['consommationJournaliere'] as num?)?.toDouble() ?? 0.0,
      nombreJours: (json['nombreJours'] as num?)?.toInt() ?? 0,
      debut: periode['debut']?.toString() ?? '',
      fin: periode['fin']?.toString() ?? '',
    );
  }
}
