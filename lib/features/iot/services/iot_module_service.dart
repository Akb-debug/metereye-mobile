import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import '../models/iot_module_request.dart';
import '../models/iot_module_response.dart';

class IotModuleService {
  Future<IotModuleResponse> createModule(
      String token, IotModuleRequest request) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.iotModulesUrl),
          headers: _headers(token),
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    _assertOk(res, 'Erreur lors de la creation du module');
    return IotModuleResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<IotModuleResponse>> getModules(String token) async {
    final res = await http
        .get(Uri.parse(AppConfig.iotModulesUrl), headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    _assertOk(res, 'Erreur lors de la recuperation des modules');
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => IotModuleResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IotModuleResponse> getModule(String token, String deviceCode) async {
    final res = await http
        .get(
          Uri.parse('${AppConfig.iotModulesUrl}/$deviceCode'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));

    _assertOk(res, 'Module introuvable');
    return IotModuleResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteModule(String token, String deviceCode) async {
    final res = await http
        .delete(
          Uri.parse('${AppConfig.iotModulesUrl}/$deviceCode'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));

    _assertOk(res, 'Erreur lors de la desactivation du module');
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  void _assertOk(http.Response res, String defaultMsg) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String msg = defaultMsg;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      msg = body['message']?.toString() ??
          body['error']?.toString() ??
          defaultMsg;
    } catch (_) {}
    throw IotException(_mapCode(res.statusCode, msg));
  }

  String _mapCode(int code, String fallback) => switch (code) {
        400 => 'Données invalides — vérifiez le formulaire.',
        401 => 'Session expirée, veuillez vous reconnecter.',
        403 => 'Accès refusé à ce compteur.',
        404 => 'Module introuvable.',
        409 => 'Un module avec cet identifiant existe déjà.',
        422 => 'Données invalides. Vérifiez les champs saisis.',
        500 => 'Erreur serveur. Réessayez dans quelques instants.',
        503 => 'Service temporairement indisponible.',
        _   => fallback,
      };
}

class IotException implements Exception {
  final String message;
  const IotException(this.message);
  @override
  String toString() => message;
}
