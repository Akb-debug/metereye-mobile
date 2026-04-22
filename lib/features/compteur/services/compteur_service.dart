import 'dart:convert';
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
    final response = await client.post(
      Uri.parse(AppConfig.compteursUrl),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CompteurResponse.fromJson(jsonDecode(response.body));
    }

    throw Exception(_extractMessage(response.body));
  }

  Future<ModeLectureResponse> configurerModeLecture({
    required String token,
    required int compteurId,
    required ConfigureModeLectureRequest request,
  }) async {
    final response = await client.post(
      Uri.parse('${AppConfig.compteursUrl}/$compteurId/mode-lecture'),
      headers: _headers(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ModeLectureResponse.fromJson(jsonDecode(response.body));
    }

    throw Exception(_extractMessage(response.body));
  }

  String _extractMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? 'Une erreur est survenue';
    } catch (_) {
      return 'Une erreur est survenue';
    }
  }
}