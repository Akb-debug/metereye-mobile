// ✅ CRÉÉ — nouveau fichier
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../models/consumption_stats_model.dart';
import '../models/reading_model.dart';
import '../services/meter_service.dart';

class HistoriqueProvider extends ChangeNotifier {
  final MeterService _service;

  HistoriqueProvider({MeterService? service})
      : _service = service ?? MeterService();

  String selectedPeriod = '30 jours';
  ConsumptionStatsModel? stats;
  List<ReadingModel> releves = [];
  bool isLoadingStats = false;
  bool isLoadingReleves = false;
  String? errorStats;
  String? errorReleves;

  static const Map<String, int> _periodDays = {
    '7 jours': 7,
    '30 jours': 30,
    '3 mois': 90,
  };

  /// Charge stats et relevés en parallèle pour l'écran historique
  Future<void> loadHistorique(int compteurId) async {
    await Future.wait([
      _loadStats(compteurId),
      _loadReleves(compteurId),
    ]);
  }

  /// Change la période sélectionnée et recharge uniquement les relevés
  Future<void> changerPeriode(String periode, int compteurId) async {
    selectedPeriod = periode;
    notifyListeners();
    await _loadReleves(compteurId);
  }

  /// Recharge l'ensemble des données
  Future<void> refresh(int compteurId) => loadHistorique(compteurId);

  Future<void> _loadStats(int compteurId) async {
    isLoadingStats = true;
    errorStats = null;
    notifyListeners();
    try {
      stats = await _service.getCompteurStats(compteurId);
    } catch (e) {
      errorStats = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> _loadReleves(int compteurId) async {
    isLoadingReleves = true;
    errorReleves = null;
    notifyListeners();
    try {
      final days = _periodDays[selectedPeriod] ?? 30;
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final response = await _service.getReadingsByMeter(compteurId, size: 100);
      releves = response.content
          .where((r) => r.dateTime.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      errorReleves = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingReleves = false;
      notifyListeners();
    }
  }

  // ── Dernières lectures ─────────────────────────────────────────────────────

  /// Les 5 relevés les plus récents pour la liste
  List<ReadingModel> get dernieresLectures =>
      releves.reversed.take(5).toList();

  // ── Getters graphe fl_chart ───────────────────────────────────────────────

  /// Points pour le LineChart (x = index, y = valeur compteur)
  List<FlSpot> get spotsForChart => List.generate(
        releves.length,
        (i) => FlSpot(i.toDouble(), releves[i].valeur),
      );

  /// Labels de l'axe X (format "jj/mm")
  List<String> get labelsForChart =>
      releves.map((r) => r.dateLabel).toList();

  /// Valeur max Y avec 20 % de marge
  double get maxYChart {
    if (releves.isEmpty) return 1000;
    final max = releves.map((r) => r.valeur).reduce((a, b) => a > b ? a : b);
    return max * 1.2;
  }

  /// Valeur min Y avec 10 % de marge vers le bas
  double get minYChart {
    if (releves.isEmpty) return 0;
    final min = releves.map((r) => r.valeur).reduce((a, b) => a < b ? a : b);
    return (min * 0.9).clamp(0.0, double.infinity);
  }

  /// True si le relevé à [index] représente une recharge (valeur monte)
  bool isRechargePoint(int index) {
    if (index <= 0 || index >= releves.length) return false;
    return releves[index].valeur > releves[index - 1].valeur;
  }

  // ── Getters SummaryCard ───────────────────────────────────────────────────

  /// Consommation totale sur la période (somme des consommationCalculee > 0)
  String get totalConsommeFormatted {
    final total = releves
        .where((r) => r.consommationCalculee != null && r.consommationCalculee! > 0)
        .fold(0.0, (sum, r) => sum + r.consommationCalculee!);

    if (total > 0) return '${total.toStringAsFixed(1)} kWh';

    // Fallback sur les stats agrégées du backend
    if (stats != null) {
      final days = _periodDays[selectedPeriod] ?? 30;
      final v = days <= 7
          ? (stats!.consommationSemaine ?? 0)
          : (stats!.consommationMois ?? 0);
      if (v > 0) return '${v.toStringAsFixed(1)} kWh';
    }
    return '--';
  }

  /// Variation vs période précédente (non fournie par le backend actuellement)
  String get variationFormatted => '--';

  /// Consommation moyenne journalière
  String get moyenneFormatted {
    final v = stats?.consommationMoyenneJour ?? 0;
    return v > 0 ? '${v.toStringAsFixed(1)} kWh' : '--';
  }

  /// Erreur combinée (stats + relevés), la première non-nulle
  String? get error => errorStats ?? errorReleves;
}
