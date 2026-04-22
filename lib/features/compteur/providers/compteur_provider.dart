import 'package:flutter/foundation.dart';
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

      // Étape 1: Création du compteur
      createdCompteur = await service.createCompteur(
        token: token,
        request: compteurRequest,
      );

      // Étape 2: Configuration du mode de lecture (optionnelle pour la redirection)
      try {
        configuredMode = await service.configurerModeLecture(
          token: token,
          compteurId: createdCompteur!.id,
          request: modeRequest,
        );
      } catch (modeError) {
        debugPrint('Erreur configuration mode lecture: $modeError');
        // On continue même si la configuration du mode échoue
        // Le compteur est créé, l'utilisateur peut continuer
      }

      return true; // Succès car le compteur est créé
    } catch (e) {
      debugPrint('Erreur CompteurProvider: $e');

      final message = e.toString().replaceFirst('Exception: ', '').trim();

      if (message.contains('référence existe déjà') ||
          message.contains('reference existe déjà') ||
          message.contains('duplicate') ||
          message.contains('Conflit détecté')) {
        errorMessage = "Un compteur avec cette référence existe déjà.";
      } else if (message.contains('Session expirée') ||
          message.contains('JWT') ||
          message.contains('401')) {
        errorMessage = "Votre session a expiré. Veuillez vous reconnecter.";
      } else if (message.contains('Impossible de contacter le serveur')) {
        errorMessage = "Impossible de contacter le serveur. Vérifie que le backend est démarré.";
      } else if (message.contains('mode de lecture')) {
        errorMessage = message.isNotEmpty
            ? message
            : "Erreur lors de la configuration du mode de lecture.";
      } else {
        errorMessage = message.isNotEmpty
            ? message
            : "Une erreur est survenue lors de la création du compteur.";
      }

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