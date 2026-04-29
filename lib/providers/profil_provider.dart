// ✅ CRÉÉ — nouveau fichier
// Gère le chargement et la mise à jour du profil utilisateur, du module IoT
// et du compteur actif pour ProfilScreen.

import 'package:flutter/foundation.dart';

import '../models/meter_model.dart';
import '../models/module_iot_model.dart';
import '../models/user_profile_model.dart';
import '../services/meter_service.dart';

class ProfilProvider extends ChangeNotifier {
  final MeterService _api;

  ProfilProvider({MeterService? api}) : _api = api ?? MeterService();

  // ── État ──────────────────────────────────────────────────────────────────
  UserProfileModel? user;
  ModuleIotModel? module;
  MeterModel? compteurActif;

  bool isLoading = false;
  bool isSavingSettings = false;
  String? error;

  // États locaux des switchs (synchronisés depuis [user] après chargement)
  bool switchCreditFaible = false;
  bool switchCoupureIminente = false;
  bool switchRapportHebdo = false;
  bool switchNotifPic = false;
  bool switchPartageProprietaire = false;

  // ── Getters d'affichage ───────────────────────────────────────────────────

  /// Initiales à afficher dans l'avatar (ex. "JD")
  String get initialesAvatar => user?.initiales ?? '??';

  /// Nom complet (ex. "Jean Doe")
  String get nomAffiche => user?.nomComplet ?? 'Chargement…';

  /// Adresse e-mail
  String get emailAffiche => user?.email ?? '';

  /// true si le module IoT est en ligne
  bool get isIoTConnecte => module?.isOnline ?? false;

  /// Titre du module (ex. "ESP32-CAM")
  String get moduleTitre => module?.typeLabel ?? 'Aucun module';

  /// Statut lisible du module
  String get moduleStatut =>
      (module?.isOnline ?? false) ? 'actif et synchronisé' : 'hors ligne';

  /// Horodatage de la dernière lecture
  String get derniereLecture => module?.lastSeenFormatted ?? '--';

  /// Type du compteur actif
  String get compteurType => compteurActif?.typeCompteur ?? '--';

  /// Référence / numéro du compteur
  String get compteurNumero => compteurActif?.reference ?? '--';

  /// Adresse / quartier du compteur
  String get compteurAdresse => compteurActif?.adresse ?? '--';

  // ── Chargement ────────────────────────────────────────────────────────────

  /// Charge le profil, le module et le premier compteur en parallèle.
  Future<void> loadProfil() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadUserProfile(),
        _loadModule(),
        _loadCompteur(),
      ]);
      _initSwitchesFromUser();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge toutes les données (pull-to-refresh ou retry).
  Future<void> refresh() => loadProfil();

  // ── Actions utilisateur ───────────────────────────────────────────────────

  /// Bascule un switch de notification avec optimistic update.
  /// [key] correspond aux clés "notifPush", "notifSms", "notifEmail",
  /// "creditFaible", "coupureIminente", "rapportHebdo", "notifPic",
  /// "partageProprietaire".
  Future<void> toggleNotification(String key, bool value) async {
    _updateSwitchLocally(key, value);
    notifyListeners();

    try {
      isSavingSettings = true;
      notifyListeners();

      switch (key) {
        case 'creditFaible':
          await _api.updateNotifications(push: value);
          break;
        case 'coupureIminente':
          await _api.updateNotifications(sms: value);
          break;
        case 'rapportHebdo':
          await _api.updateNotifications(email: value);
          break;
        // notifPic et partageProprietaire : pas encore de mapping backend
        default:
          break;
      }
    } catch (e) {
      // Rollback en cas d'erreur
      _updateSwitchLocally(key, !value);
      rethrow;
    } finally {
      isSavingSettings = false;
      notifyListeners();
    }
  }

  // ── Helpers privés ────────────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    user = await _api.getUserProfile();
  }

  Future<void> _loadModule() async {
    module = await _api.getMyModule();
  }

  Future<void> _loadCompteur() async {
    final list = await _api.getMesCompteurs();
    compteurActif = list.isNotEmpty ? list.first : null;
  }

  /// Synchronise les états des switchs depuis les préférences backend.
  void _initSwitchesFromUser() {
    if (user == null) return;
    switchCreditFaible = user!.notificationPush;
    switchCoupureIminente = user!.notificationSms;
    switchRapportHebdo = user!.notificationEmail;
    // notifPic et partageProprietaire : pas de champ dédié côté backend
    switchNotifPic = false;
    switchPartageProprietaire = false;
  }

  void _updateSwitchLocally(String key, bool value) {
    switch (key) {
      case 'creditFaible':
        switchCreditFaible = value;
        break;
      case 'coupureIminente':
        switchCoupureIminente = value;
        break;
      case 'rapportHebdo':
        switchRapportHebdo = value;
        break;
      case 'notifPic':
        switchNotifPic = value;
        break;
      case 'partageProprietaire':
        switchPartageProprietaire = value;
        break;
    }
  }
}
