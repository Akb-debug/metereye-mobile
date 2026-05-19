// ✅ CRÉÉ — nouveau fichier
// Même pattern que MeterService : http + SharedPreferences (pas Dio)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';
import '../models/alerte_model.dart';

class AlerteService {
  static const String _alertesUrl = '${AppConfig.baseUrl}/alertes';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Exception _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      final msg = data is Map ? data['message']?.toString() : null;
      if (msg != null && msg.isNotEmpty) return Exception(msg);
    } catch (_) {}
    switch (response.statusCode) {
      case 401:
        return Exception('Session expirée. Veuillez vous reconnecter.');
      case 403:
        return Exception('Accès non autorisé.');
      case 404:
        return Exception('Ressource introuvable.');
      default:
        return Exception('Erreur HTTP ${response.statusCode}.');
    }
  }

  /// GET /api/alertes — toutes les alertes de l'utilisateur connecté
  Future<List<AlerteModel>> fetchAlertes() async {
    final headers = await _getHeaders();
    final response =
        await http.get(Uri.parse(_alertesUrl), headers: headers);
    debugPrint('fetchAlertes: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list
          .map((e) => AlerteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  /// GET /api/alertes/non-lues — alertes non lues uniquement
  Future<List<AlerteModel>> fetchAlertesNonLues() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_alertesUrl/non-lues'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list
          .map((e) => AlerteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _handleError(response);
  }

  /// PATCH /api/alertes/{id}/lue — marque une alerte spécifique comme lue
  Future<void> marquerCommeLue(int id) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_alertesUrl/$id/lue'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _handleError(response);
    }
  }

  /// PATCH /api/alertes/tout-lu — marque toutes les alertes comme lues
  Future<void> marquerToutesLues() async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_alertesUrl/tout-lu'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _handleError(response);
    }
  }
}
