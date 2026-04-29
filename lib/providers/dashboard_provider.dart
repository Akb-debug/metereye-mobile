import 'package:flutter/foundation.dart';

import '../models/consumption_stats_model.dart';
import '../models/meter_model.dart';
import '../models/reading_model.dart';
import '../services/meter_service.dart';

class DashboardProvider extends ChangeNotifier {
  final MeterService _service;

  DashboardProvider({MeterService? service}) : _service = service ?? MeterService();

  MeterModel? compteurActif;
  ConsumptionStatsModel? stats;
  ReadingModel? latestReading;
  bool isLoading = false;
  String? error;

  Future<void> loadDashboard() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final compteurs = await _service.getMesCompteurs();
      final actif = compteurs.where((c) => c.actif).firstOrNull ?? compteurs.firstOrNull;

      if (actif == null) {
        error = 'Aucun compteur trouvé.';
        return;
      }

      compteurActif = actif;
      notifyListeners();

      final results = await Future.wait([
        _service
            .getCompteurStats(actif.id)
            .then<Object?>((v) => v)
            .catchError((_) => null),
        _service
            .getLatestReading(actif.id)
            .then<Object?>((v) => v)
            .catchError((_) => null),
      ]);

      stats = results[0] as ConsumptionStatsModel?;
      latestReading = results[1] as ReadingModel?;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  String get numCompteur => compteurActif?.reference ?? '--';

  String get creditUnites {
    final v = compteurActif?.valeurActuelle ?? 0;
    return compteurActif?.isCashPower == true
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
  }

  int get joursRestants => stats?.joursRestants ?? 0;
  String get dateFinEstimee => stats?.dateEpuisementFormatted ?? '--';

  double get creditPct =>
      ((compteurActif?.valeurActuelle ?? 0) / 1000.0).clamp(0.0, 1.0);

  String get consoAujourd => stats?.formattedConsommationJour ?? '--';
  String get consoMois => stats?.formattedConsommationMois ?? '--';
  String get moyJournaliere => stats?.formattedConsommationMoyenneJour ?? '--';

  List<Map<String, dynamic>> get conso7j => stats?.conso7j ?? [];
  double get maxConso7j => stats?.maxConso7j ?? 6.0;
  double get moyenneConso => stats?.consommationMoyenneJour ?? 0;

  String get derniereLeture {
    if (latestReading == null) return '--:--';
    final d = latestReading!.dateTime;
    return '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
  }
}
