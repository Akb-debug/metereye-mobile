import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../models/releve.dart';

class ReleveService {
  final http.Client client;

  ReleveService({http.Client? client}) : client = client ?? http.Client();

  Map<String, String> _headers(String token) {
    // Supprime un éventuel préfixe "Bearer " déjà présent dans le token stocké
    final cleaned = token.trim().startsWith('Bearer ')
        ? token.trim().substring(7).trim()
        : token.trim();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $cleaned',
    };
  }

  void _logRequest(String method, String url, Map<String, String> headers, [String? body]) {
    debugPrint('──────────────────────────────────────');
    debugPrint('[$method] $url');
    headers.forEach((k, v) {
      // Masque la majorité du token dans les logs
      if (k == 'Authorization') {
        final parts = v.split(' ');
        final masked = parts.length == 2
            ? '${parts[0]} ${parts[1].substring(0, parts[1].length.clamp(0, 20))}...'
            : v;
        debugPrint('  $k: $masked');
      } else {
        debugPrint('  $k: $v');
      }
    });
    if (body != null) debugPrint('  BODY: $body');
    debugPrint('──────────────────────────────────────');
  }

  void _logResponse(http.Response response) {
    debugPrint('◀ STATUS : ${response.statusCode}');
    // www-authenticate révèle le motif exact du rejet JWT
    final wwwAuth = response.headers['www-authenticate'];
    if (wwwAuth != null) debugPrint('◀ WWW-AUTHENTICATE: $wwwAuth');
    // Décodage utf8 explicite pour ne pas manquer de corps encodé
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    debugPrint('◀ BODY: ${body.isEmpty ? "(vide)" : body}');
    debugPrint('◀ CONTENT-TYPE: ${response.headers['content-type']}');
    debugPrint('──────────────────────────────────────');
  }

  /// POST /api/readings/manual
  Future<Releve> createManualReleve({
    required String token,
    required int meterId,
    required double value,
    String? comment,
  }) async {
    const url = AppConfig.relevesUrl;
    final headers = _headers(token);
    final bodyMap = {
      'meterId': meterId,
      'value': value,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };
    final bodyJson = jsonEncode(bodyMap);

    _logRequest('POST', url, headers, bodyJson);

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: headers,
        body: bodyJson,
      );

      _logResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Releve.fromJson(jsonDecode(response.body));
      }

      throw Exception(_extractMessage(response));
    } on http.ClientException catch (e) {
      debugPrint('CLIENT EXCEPTION: $e');
      throw Exception('Impossible de contacter le serveur. Vérifie ta connexion.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// GET /api/readings/meters/{meterId}?page=0&size=20
  Future<List<Releve>> getCompteurReleves({
    required String token,
    required int compteurId,
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/readings/meters/$compteurId')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});
    final headers = _headers(token);

    _logRequest('GET', uri.toString(), headers);

    try {
      final response = await client.get(uri, headers: headers);

      _logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> content = data['content'] as List<dynamic>;
        return content
            .map((item) => Releve.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception(_extractMessage(response));
    } on http.ClientException catch (e) {
      debugPrint('CLIENT EXCEPTION: $e');
      throw Exception('Impossible de contacter le serveur.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur inattendue: $e');
    }
  }

  String _extractMessage(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString() ??
            data['error']?.toString() ??
            data['detail']?.toString();
        if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Données invalides (400).';
      case 401:
        final wwwAuth = response.headers['www-authenticate'] ?? '';
        return 'Non autorisé (401). $wwwAuth'.trim();
      case 403:
        return 'Accès refusé (403). Vous n\'êtes pas autorisé sur ce compteur.';
      case 404:
        return 'Endpoint introuvable (404). Vérifiez l\'URL backend.';
      case 409:
        return 'Conflit (409). Un relevé similaire existe déjà.';
      case 500:
        return 'Erreur serveur (500). Réessayez plus tard.';
      default:
        return 'Erreur (${response.statusCode}): $body';
    }
  }
}
