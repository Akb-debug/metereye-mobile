import 'package:flutter/foundation.dart';
import '../models/releve.dart';
import '../services/releve_service.dart';

class ReleveProvider extends ChangeNotifier {
  final ReleveService service;

  ReleveProvider({required this.service});

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  double? consommationEstimee;
  List<Releve> releves = [];

  void calculerConsommation(double nouvelleValeur, double? valeurPrecedente) {
    if (valeurPrecedente == null) {
      consommationEstimee = nouvelleValeur;
    } else if (nouvelleValeur >= valeurPrecedente) {
      consommationEstimee = nouvelleValeur - valeurPrecedente;
    } else {
      consommationEstimee = null;
    }
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    consommationEstimee = null;
    notifyListeners();
  }

  Future<bool> soumettreReleve({
    required String token,
    required int meterId,
    required double value,
    String? comment,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      notifyListeners();

      final releve = await service.createManualReleve(
        token: token,
        meterId: meterId,
        value: value,
        comment: comment,
      );

      releves.insert(0, releve);
      successMessage = 'Relevé ajouté avec succès';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> chargerReleves({
    required String token,
    required int compteurId,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      releves = await service.getCompteurReleves(
        token: token,
        compteurId: compteurId,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
