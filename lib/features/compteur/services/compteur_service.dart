import 'dart:convert';
import 'dart:typed_data';
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
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CompteurResponse>> getMesCompteurs({
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(AppConfig.compteursUrl),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('getMesCompteurs type=${decoded.runtimeType}');
        debugPrint('getMesCompteurs body=${response.body}');

        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          // Cherche la première clé qui contient une List
          final mapKeys = decoded.keys.toList();
          debugPrint('getMesCompteurs keys=$mapKeys');
          final listKey = mapKeys.firstWhere(
            (k) => decoded[k] is List,
            orElse: () => '',
          );
          if (listKey.isNotEmpty) {
            list = decoded[listKey] as List<dynamic>;
          } else {
            throw Exception('Clés reçues : $mapKeys');
          }
        } else {
          throw Exception('Format de réponse inattendu : ${decoded.runtimeType}');
        }

        return list
            .map((e) => CompteurResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception(_extractMessage(response));
    } on http.ClientException {
      throw Exception("Impossible de contacter le serveur. Vérifie ta connexion.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Erreur inattendue lors du chargement des compteurs : $e");
    }
  }

  /// GET /api/compteurs/{id}/statut-configuration
  /// Retourne le mode de lecture configuré pour un compteur ('MANUAL', 'ESP32_CAM', 'SENSOR')
  Future<String?> getModeLecture({
    required String token,
    required int compteurId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConfig.compteursUrl}/$compteurId/statut-configuration'),
        headers: _headers(token),
      );

      debugPrint('── statut-configuration[$compteurId] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Le champ peut s'appeler modeLecture ou modeLectureConfigure selon le backend
        return (data['modeLecture'] ?? data['modeLectureConfigure'])?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('── getModeLecture erreur: $e');
      return null;
    }
  }

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

  /// POST /api/readings/upload — envoie une image (bytes) et retourne le relevé OCR.
  Future<Map<String, dynamic>> uploadImageReading({
    required String token,
    required int meterId,
    required Uint8List imageBytes,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/readings/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'})
        ..fields['meterId'] = '$meterId'
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'capture.jpg'));
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      debugPrint('uploadImageReading status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception(_extractMessage(response));
    } on http.ClientException {
      throw Exception('Impossible de contacter le serveur.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Erreur lors de l'upload de l'image: $e");
    }
  }

  /// Extrait l'userId (int) depuis le payload JWT sans vérifier la signature.
  /// Cherche les claims : userId → id → sub (si numérique).
  static int? extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)))
          as Map<String, dynamic>;
      final raw = decoded['userId'] ?? decoded['id'] ?? decoded['sub'];
      if (raw == null) return null;
      if (raw is int) return raw;
      return int.tryParse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  /// POST /api/module-devices — crée et associe un module ESP32-CAM au compteur.
  Future<void> createAndAssociateModuleEsp32({
    required String token,
    required int userId,
    required int compteurId,
    required String uuid,
    required String ipAddress,
    required String wifiSsid,
    int captureInterval = 3600,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(AppConfig.moduleDevicesUrl),
        headers: _headers(token),
        body: jsonEncode({
          'userId': userId,
          'compteurId': compteurId,
          'uuid': uuid,
          'ipAddress': ipAddress,
          'wifiSsid': wifiSsid,
          'captureInterval': captureInterval,
        }),
      );
      debugPrint('createAndAssociateModuleEsp32 status=${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractMessage(response));
      }
    } on http.ClientException {
      throw Exception('Impossible de contacter le serveur.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Erreur lors de l'association du module ESP32: $e");
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