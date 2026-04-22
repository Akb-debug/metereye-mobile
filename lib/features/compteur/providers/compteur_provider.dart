import 'package:flutter/material.dart';
import '../models/compteur_response.dart';
import '../models/create_compteur_request.dart';
import '../models/configure_mode_lecture_request.dart';
import '../models/mode_lecture_response.dart';
import '../services/compteur_service.dart';

class CompteurProvider extends ChangeNotifier {
  final CompteurService service;

  CompteurProvider({required this.service});

  bool isLoading = false;
  String? errorMessage;

  CompteurResponse? createdCompteur;
  ModeLectureResponse? configuredMode;

  Future<bool> createCompteurAndConfigureMode({
    required String token,
    required CreateCompteurRequest compteurRequest,
    required ConfigureModeLectureRequest modeRequest,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      createdCompteur = await service.createCompteur(
        token: token,
        request: compteurRequest,
      );

      configuredMode = await service.configurerModeLecture(
        token: token,
        compteurId: createdCompteur!.id,
        request: modeRequest,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    errorMessage = null;
    createdCompteur = null;
    configuredMode = null;
    notifyListeners();
  }
}