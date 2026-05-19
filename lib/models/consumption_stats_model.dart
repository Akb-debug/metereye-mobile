class ConsumptionStatsModel {
  final double? consommationJour;
  final double? consommationSemaine;
  final double? consommationMois;
  final double? consommationMoyenneJour;
  final double? creditRestant;
  final DateTime? dateEstimationEpuisement;
  final Map<String, double> consommationParJour;

  ConsumptionStatsModel({
    this.consommationJour,
    this.consommationSemaine,
    this.consommationMois,
    this.consommationMoyenneJour,
    this.creditRestant,
    this.dateEstimationEpuisement,
    this.consommationParJour = const {},
  });

  factory ConsumptionStatsModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> parJour = {};
    if (json['consommationParJour'] is Map) {
      (json['consommationParJour'] as Map).forEach((k, v) {
        parJour[k.toString()] = (v as num?)?.toDouble() ?? 0.0;
      });
    }

    return ConsumptionStatsModel(
      consommationJour: (json['consommationJour'] as num?)?.toDouble(),
      consommationSemaine: (json['consommationSemaine'] as num?)?.toDouble(),
      consommationMois: (json['consommationMois'] as num?)?.toDouble(),
      consommationMoyenneJour: (json['consommationMoyenneJour'] as num?)?.toDouble(),
      creditRestant: (json['creditRestant'] as num?)?.toDouble(),
      dateEstimationEpuisement: json['dateEstimationEpuisement'] != null
          ? DateTime.tryParse(json['dateEstimationEpuisement'].toString())
          : null,
      consommationParJour: parJour,
    );
  }

  int get joursRestants {
    if (dateEstimationEpuisement == null) return 0;
    return dateEstimationEpuisement!.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  String get dateEpuisementFormatted {
    if (dateEstimationEpuisement == null) return '--';
    final d = dateEstimationEpuisement!;
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${d.day} ${mois[d.month - 1]}';
  }

  List<Map<String, dynamic>> get conso7j {
    if (consommationParJour.isEmpty) return [];
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    // Trie par date croissante puis prend les 7 derniers
    final sorted = consommationParJour.entries.toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.key);
        final db = DateTime.tryParse(b.key);
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });

    final last7 = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    return last7.map((e) {
      final date = DateTime.tryParse(e.key);
      final label = date != null ? jours[date.weekday - 1] : e.key;
      return {'jour': label, 'kwh': e.value};
    }).toList();
  }

  double get maxConso7j {
    if (conso7j.isEmpty) return 6.0;
    final max = conso7j.map((e) => (e['kwh'] as double)).reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble().clamp(1.0, double.infinity);
  }

  String get formattedConsommationJour =>
      consommationJour == null ? 'N/A' : '${consommationJour!.toStringAsFixed(2)} kWh';

  String get formattedConsommationMois =>
      consommationMois == null ? 'N/A' : '${consommationMois!.toStringAsFixed(2)} kWh';

  String get formattedConsommationMoyenneJour =>
      consommationMoyenneJour == null ? 'N/A' : '${consommationMoyenneJour!.toStringAsFixed(0)} u/j';

  bool get isCreditFaible => (creditRestant ?? 0) < 200;
  bool get isCreditCritique => (creditRestant ?? 0) < 50;
}
