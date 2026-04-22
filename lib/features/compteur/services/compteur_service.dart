import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../models/compteur_response.dart';
import '../models/create_compteur_request.dart';
import '../models/configure_mode_lecture_request.dart';
import '../models/mode_lecture_response.dart';

class CompteurService {
  final http.Client client;

  CompteurService({http.Client? client}) : client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<CompteurResponse> createCompteur({
    required String token,
    required CreateCompteurRequest request,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(AppConfig.compteursUrl),
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('CREATE COMPTEUR STATUS: ${response.statusCode}');
      debugPrint('CREATE COMPTEUR BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CompteurResponse.fromJson(jsonDecode(response.body));
      }

      throw Exception(_extractMessage(response));
    } on http.ClientException {
      throw Exception("Impossible de contacter le serveur. Vérifie ta connexion.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Une erreur inattendue est survenue lors de la création du compteur.");
    }
  }

  Future<ModeLectureResponse> configurerModeLecture({
    required String token,
    required int compteurId,
    required ConfigureModeLectureRequest request,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConfig.compteursUrl}/$compteurId/mode-lecture'),
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );

      debugPrint('MODE LECTURE STATUS: ${response.statusCode}');
      debugPrint('MODE LECTURE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ModeLectureResponse.fromJson(jsonDecode(response.body));
      }

      throw Exception(_extractMessage(response));
    } on http.ClientException {
      throw Exception("Impossible de contacter le serveur. Vérifie ta connexion.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Une erreur inattendue est survenue lors de la configuration du mode de lecture.");
    }
  }

  String _extractMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        if (data['message'] != null &&
            data['message'].toString().trim().isNotEmpty) {
          return data['message'].toString();
        }

        if (data['error'] != null &&
            data['error'].toString().trim().isNotEmpty) {
          return data['error'].toString();
        }

        if (data['errors'] != null) {
          return data['errors'].toString();
        }
      }
    } catch (_) {
      // ignore json parse error
    }

    switch (response.statusCode) {
      case 400:
        return "Données invalides. Vérifie les champs saisis.";
      case 401:
        return "Session expirée. Veuillez vous reconnecter.";
      case 403:
        return "Accès refusé.";
      case 404:
        return "Ressource introuvable.";
      case 409:
        return "Conflit détecté. Cette référence existe peut-être déjà.";
      case 500:
        return "Erreur serveur. Réessaie plus tard.";
      default:
        return "Une erreur inattendue est survenue.";
    }
  }
}