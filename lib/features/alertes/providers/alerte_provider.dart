// ✅ CRÉÉ — nouveau fichier
// Pattern identique à HistoriqueProvider/DashboardProvider : ChangeNotifier

import 'package:flutter/foundation.dart';

import '../models/alerte_model.dart';
import '../services/alerte_service.dart';

class AlerteProvider extends ChangeNotifier {
  final AlerteService _service;

  AlerteProvider({AlerteService? service})
      : _service = service ?? AlerteService();

  // ── États ─────────────────────────────────────────────────────────────────
  List<AlerteModel> alertes = [];
  bool isLoading = false;
  String? error;

  // ── Getters ────────────────────────────────────────────────────────────────

  /// Nombre d'alertes non lues calculé depuis la liste locale
  int get nonLuesCount => alertes.where((a) => !a.lue).length;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Charge toutes les alertes depuis le backend
  Future<void> loadAlertes() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      alertes = await _service.fetchAlertes();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Marque une alerte comme lue avec optimistic update.
  /// Rollback + rechargement depuis le backend en cas d'échec.
  Future<void> marquerCommeLue(int id) async {
    final index = alertes.indexWhere((a) => a.id == id);
    if (index == -1 || alertes[index].lue) return;

    // Optimistic update
    alertes[index] = alertes[index].copyWith(lue: true);
    notifyListeners();

    try {
      await _service.marquerCommeLue(id);
    } catch (e) {
      debugPrint('AlerteProvider.marquerCommeLue erreur: $e');
      // Rollback : recharge la liste depuis le backend
      await loadAlertes();
    }
  }

  /// Marque toutes les alertes comme lues avec optimistic update.
  /// Appelle l'endpoint individuel en parallèle pour chaque alerte non lue.
  Future<void> marquerToutesLues() async {
    final nonLues = alertes.where((a) => !a.lue).toList();
    if (nonLues.isEmpty) return;

    // Optimistic update
    alertes = alertes.map((a) => a.copyWith(lue: true)).toList();
    notifyListeners();

    try {
      await Future.wait(nonLues.map((a) => _service.marquerCommeLue(a.id)));
    } catch (e) {
      debugPrint('AlerteProvider.marquerToutesLues erreur: $e');
      // Rollback
      await loadAlertes();
    }
  }

  /// Recharge les alertes (pull-to-refresh ou retry)
  Future<void> refresh() => loadAlertes();
}
