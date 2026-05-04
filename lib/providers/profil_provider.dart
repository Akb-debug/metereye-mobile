// ✅ CRÉÉ — nouveau fichier

import 'package:flutter/foundation.dart';

import '../models/meter_model.dart';
import '../models/module_iot_model.dart';
import '../models/user_profile_model.dart';
import '../services/meter_service.dart';

class ProfilProvider extends ChangeNotifier {
  final MeterService _service;

  ProfilProvider({MeterService? service}) : _service = service ?? MeterService();

  // ── États ─────────────────────────────────────────────────────────────────
  UserProfileModel? user;
  ModuleIotModel? module;
  MeterModel? compteurActif;
  bool isLoading = false;
  bool isSavingSettings = false;
  String? error;

  // États locaux des switchs — initialisés depuis user lors du chargement
  bool switchCreditFaible = true;
  bool switchCoupureIminente = false;
  bool switchRapportHebdo = true;
  bool switchNotifPic = true;
  bool switchPartageProprietaire = false;

  // ── Chargement ────────────────────────────────────────────────────────────

  /// Charge profil + module + compteur actif en parallèle, puis synchronise les switchs
  Future<void> loadProfil() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([
        _loadUserProfile(),
        _loadModule(),
        _loadCompteurActif(),
      ]);
      _initSwitchesFromUser();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      user = await _service.getUserProfile();
    } catch (e) {
      // Erreur critique : surface dans le banner de l'écran
      error = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _loadModule() async {
    try {
      module = await _service.getMyModule();
    } catch (e) {
      // Non bloquant : l'absence de module IoT est un état valide
      debugPrint('ProfilProvider._loadModule: $e');
    }
  }

  Future<void> _loadCompteurActif() async {
    try {
      final list = await _service.getMesCompteurs();
      compteurActif =
          list.where((c) => c.actif).firstOrNull ?? list.firstOrNull;
    } catch (e) {
      // Non bloquant
      debugPrint('ProfilProvider._loadCompteurActif: $e');
    }
  }

  /// Synchronise les switchs depuis les préférences de notification de l'utilisateur
  void _initSwitchesFromUser() {
    if (user == null) return;
    switchCreditFaible = user!.notificationPush;
    switchCoupureIminente = user!.notificationSms;
    switchRapportHebdo = user!.notificationEmail;
    // notifPic et partageProprietaire n'ont pas de champ backend : gardent leur état par défaut
  }

  // ── Toggle notifications ──────────────────────────────────────────────────

  /// Optimistic update : met à jour l'UI immédiatement, appelle le backend,
  /// rollback et rethrow si erreur (le widget affichera un SnackBar).
  Future<void> toggleNotification(String key, bool value) async {
    _updateSwitchLocally(key, value);
    notifyListeners();

    // Clés sans mapping backend : mise à jour locale uniquement
    if (key == 'notifPic' || key == 'partageProprietaire') return;

    isSavingSettings = true;
    notifyListeners();
    try {
      await _service.updateNotifications(
        push: key == 'creditFaible' ? value : null,
        sms: key == 'coupureIminente' ? value : null,
        email: key == 'rapportHebdo' ? value : null,
      );
    } catch (e) {
      _updateSwitchLocally(key, !value); // rollback
      rethrow;
    } finally {
      isSavingSettings = false;
      notifyListeners();
    }
  }

  void _updateSwitchLocally(String key, bool value) {
    switch (key) {
      case 'creditFaible':
        switchCreditFaible = value;
      case 'coupureIminente':
        switchCoupureIminente = value;
      case 'rapportHebdo':
        switchRapportHebdo = value;
      case 'notifPic':
        switchNotifPic = value;
      case 'partageProprietaire':
        switchPartageProprietaire = value;
    }
  }

  /// Recharge toutes les données du profil
  Future<void> refresh() => loadProfil();

  // ── Getters d'affichage ───────────────────────────────────────────────────
  String get initialesAvatar => user?.initiales ?? '??';
  String get nomAffiche => user?.nomComplet ?? 'Chargement...';
  String get emailAffiche => user?.email ?? '';
  bool get isIoTConnecte => module?.isOnline ?? false;
  String get moduleTitre => module?.typeLabel ?? 'Aucun module';
  String get moduleStatut =>
      module?.isOnline == true ? 'actif et synchronisé' : 'hors ligne';
  String get derniereLecture => module?.lastSeenFormatted ?? '--';
  String get compteurType => compteurActif?.typeCompteur ?? '--';
  String get compteurNumero => compteurActif?.reference ?? '--';
  String get compteurAdresse => compteurActif?.adresse ?? '--';
}
