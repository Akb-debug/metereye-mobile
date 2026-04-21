import 'package:flutter/material.dart';

import '../models/consumption_response_model.dart';
import '../models/consumption_stats_model.dart';
import '../models/device_model.dart';
import '../models/meter_model.dart';
import '../models/paginated_readings_response.dart';
import '../models/reading_model.dart';
import '../models/reading_request_model.dart';
import '../models/recharge_request_model.dart';
import '../services/meter_service.dart';

class MeterProvider extends ChangeNotifier {
  final MeterService _meterService = MeterService();

  List<MeterModel> _compteurs = [];
  bool _isLoadingCompteurs = false;
  String? _compteursError;
  MeterModel? _selectedCompteur;
  bool _isLoadingCompteur = false;
  String? _compteurError;
  List<ReadingModel> _releves = [];
  int _relevesPage = 0;
  int _relevesTotalPages = 1;
  int _relevesTotalElements = 0;
  bool _isLoadingReleves = false;
  String? _relevesError;
  ReadingModel? _latestReading;
  ConsumptionResponseModel? _consommation;
  ConsumptionStatsModel? _stats;
  bool _isLoadingStats = false;
  String? _statsError;
  List<DeviceModel> _devices = [];
  DeviceModel? _selectedDevice;
  bool _isLoadingOperation = false;
  String? _operationError;
  String? _operationSuccess;

  List<MeterModel> get compteurs => _compteurs;
  bool get isLoadingCompteurs => _isLoadingCompteurs;
  String? get compteursError => _compteursError;
  MeterModel? get selectedCompteur => _selectedCompteur;
  bool get isLoadingCompteur => _isLoadingCompteur;
  String? get compteurError => _compteurError;
  List<ReadingModel> get releves => _releves;
  int get relevesPage => _relevesPage;
  int get relevesTotalPages => _relevesTotalPages;
  int get relevesTotalElements => _relevesTotalElements;
  bool get isLoadingReleves => _isLoadingReleves;
  String? get relevesError => _relevesError;
  ReadingModel? get latestReading => _latestReading;
  ConsumptionResponseModel? get consommation => _consommation;
  ConsumptionStatsModel? get stats => _stats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;
  List<DeviceModel> get devices => _devices;
  DeviceModel? get selectedDevice => _selectedDevice;
  bool get isLoadingOperation => _isLoadingOperation;
  String? get operationError => _operationError;
  String? get operationSuccess => _operationSuccess;

  String _normalizePeriode(String periode) {
    switch (periode.toLowerCase()) {
      case 'day':
      case 'jour':
        return 'jour';
      case 'week':
      case 'semaine':
        return 'semaine';
      case 'year':
      case 'annee':
        return 'annee';
      case 'month':
      case 'mois':
      default:
        return 'mois';
    }
  }

  Future<void> loadCompteurs() async {
    _isLoadingCompteurs = true;
    _compteursError = null;
    notifyListeners();
    try {
      _compteurs = await _meterService.getMesCompteurs();
      _isLoadingCompteurs = false;
      notifyListeners();
    } catch (e) {
      _compteursError = e.toString().replaceAll('Exception: ', '');
      _isLoadingCompteurs = false;
      notifyListeners();
    }
  }

  Future<void> loadCompteurById(int id) async {
    _isLoadingCompteur = true;
    _compteurError = null;
    notifyListeners();
    try {
      _selectedCompteur = await _meterService.getCompteurById(id);
      _isLoadingCompteur = false;
      notifyListeners();
    } catch (e) {
      _compteurError = e.toString().replaceAll('Exception: ', '');
      _isLoadingCompteur = false;
      notifyListeners();
    }
  }

  void selectCompteur(MeterModel compteur) {
    _selectedCompteur = compteur;
    _compteurError = null;
    notifyListeners();
  }

  Future<void> loadReleves(int compteurId, {DateTime? startDate, DateTime? endDate, int page = 0, int size = 20}) async {
    _isLoadingReleves = true;
    _relevesError = null;
    notifyListeners();
    try {
      final PaginatedReadingsResponse response = await _meterService.getHistoriqueReleves(
        compteurId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        size: size,
      );
      _releves = response.content;
      _relevesPage = response.page;
      _relevesTotalPages = response.totalPages;
      _relevesTotalElements = response.totalElements;
      _isLoadingReleves = false;
      notifyListeners();
    } catch (e) {
      _relevesError = e.toString().replaceAll('Exception: ', '');
      _isLoadingReleves = false;
      notifyListeners();
    }
  }

  Future<void> loadLatestReading(int compteurId) async {
    try {
      _latestReading = await _meterService.getDernierReleve(compteurId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadStats(int compteurId, {String periode = 'mois'}) async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();
    try {
      _stats = await _meterService.getStatistiques(
        compteurId,
        periode: _normalizePeriode(periode),
      );
      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      _statsError = e.toString().replaceAll('Exception: ', '');
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> loadConsommation(int compteurId, {DateTime? startDate, DateTime? endDate}) async {
    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();
    try {
      _consommation = await _meterService.getConsommation(
        compteurId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      _statsError = e.toString().replaceAll('Exception: ', '');
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<bool> createCompteur({required String reference, required String adresse, required String typeCompteur, required double valeurInitiale}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      final meter = await _meterService.createCompteur(
        reference: reference,
        adresse: adresse,
        typeCompteur: typeCompteur,
        valeurInitiale: valeurInitiale,
      );
      _compteurs.insert(0, meter);
      _selectedCompteur = meter;
      _operationSuccess = 'Compteur créé avec succès';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> configureModeLecture(int compteurId, {required String modeLecture, String? commentaire}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      final updated = await _meterService.configureModeLecture(
        compteurId,
        modeLecture: modeLecture,
        commentaire: commentaire,
      );
      final index = _compteurs.indexWhere((c) => c.id == compteurId);
      if (index != -1) _compteurs[index] = updated;
      if (_selectedCompteur?.id == compteurId) _selectedCompteur = updated;
      _operationSuccess = 'Mode de lecture configuré';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reinitialiserCompteur({required int compteurId, required String motif, String? commentaire}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      await _meterService.reinitialiserCompteur(compteurId, motif: motif, commentaire: commentaire);
      _operationSuccess = 'Compteur réinitialisé';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> ajouterReleve(ReadingRequestModel request) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      final releve = await _meterService.ajouterReleve(request);
      _releves.insert(0, releve);
      _latestReading = releve;
      if (_selectedCompteur?.id == request.compteurId) {
        _selectedCompteur = _selectedCompteur!.copyWith(valeurActuelle: request.valeur);
      }
      _operationSuccess = 'Relevé ajouté avec succès';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechargerCompteur(RechargeRequestModel request) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      final compteur = await _meterService.rechargerCompteur(request);
      final index = _compteurs.indexWhere((c) => c.id == request.compteurId);
      if (index != -1) _compteurs[index] = compteur;
      if (_selectedCompteur?.id == request.compteurId) _selectedCompteur = compteur;
      _operationSuccess = 'Recharge effectuée avec succès';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createSensorReading({required int compteurId, required double valeur, required String deviceCode, String? commentaire}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      final releve = await _meterService.createSensorReading(
        compteurId: compteurId,
        valeur: valeur,
        deviceCode: deviceCode,
        commentaire: commentaire,
      );
      _releves.insert(0, releve);
      _latestReading = releve;
      _operationSuccess = 'Relevé capteur ajouté avec succès';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImageReading({required String filePath, required String deviceCode, String? commentaire}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      final releve = await _meterService.uploadReading(
        filePath: filePath,
        deviceCode: deviceCode,
        commentaire: commentaire,
      );
      _releves.insert(0, releve);
      _latestReading = releve;
      _operationSuccess = 'Image envoyée avec succès';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> scanDevice({required String qrCode, required int userId}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      _selectedDevice = await _meterService.scanDevice(qrCode: qrCode, userId: userId);
      _operationSuccess = _selectedDevice?.message ?? 'Module scanné';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> associateDevice({required String deviceCode, required int compteurId, int captureInterval = 3600}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      _selectedDevice = await _meterService.associateDevice(
        deviceCode: deviceCode,
        compteurId: compteurId,
        captureInterval: captureInterval,
      );
      _operationSuccess = _selectedDevice?.message ?? 'Module associé';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDeviceStatus(String deviceCode) async {
    _isLoadingOperation = true;
    _operationError = null;
    notifyListeners();
    try {
      _selectedDevice = await _meterService.getDeviceStatus(deviceCode);
      _isLoadingOperation = false;
      notifyListeners();
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
    }
  }

  Future<void> loadMyDevices() async {
    _isLoadingOperation = true;
    _operationError = null;
    notifyListeners();
    try {
      _devices = await _meterService.getMyDevices();
      _isLoadingOperation = false;
      notifyListeners();
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
    }
  }

  Future<bool> updateCaptureInterval({required String deviceCode, required int interval}) async {
    _isLoadingOperation = true;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
    try {
      await _meterService.updateCaptureInterval(deviceCode: deviceCode, interval: interval);
      _operationSuccess = 'Intervalle mis à jour';
      _isLoadingOperation = false;
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString().replaceAll('Exception: ', '');
      _isLoadingOperation = false;
      notifyListeners();
      return false;
    }
  }

  ReadingModel? getDernierReleve(int compteurId) {
    try {
      return _releves
          .where((r) => r.compteurId == compteurId)
          .reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b);
    } catch (_) {
      return null;
    }
  }

  double calculerConsommationTotale(List<ReadingModel> releves) {
    if (releves.isEmpty) return 0.0;
    double total = 0.0;
    for (int i = 1; i < releves.length; i++) {
      final diff = releves[i - 1].valeur - releves[i].valeur;
      if (diff > 0) total += diff;
    }
    return total;
  }

  void clearMessages() {
    _compteursError = null;
    _compteurError = null;
    _relevesError = null;
    _statsError = null;
    _operationError = null;
    _operationSuccess = null;
    notifyListeners();
  }

  void reset() {
    _compteurs = [];
    _selectedCompteur = null;
    _releves = [];
    _latestReading = null;
    _consommation = null;
    _stats = null;
    _devices = [];
    _selectedDevice = null;
    _compteursError = null;
    _compteurError = null;
    _relevesError = null;
    _statsError = null;
    _operationError = null;
    _operationSuccess = null;
    _isLoadingCompteurs = false;
    _isLoadingCompteur = false;
    _isLoadingReleves = false;
    _isLoadingStats = false;
    _isLoadingOperation = false;
    notifyListeners();
  }

  List<MeterModel> get compteursCashPower => _compteurs.where((c) => c.isCashPower).toList();
  List<MeterModel> get compteursClassique => _compteurs.where((c) => c.isClassique).toList();
  List<MeterModel> get compteursActifs => _compteurs.where((c) => c.actif).toList();
}
