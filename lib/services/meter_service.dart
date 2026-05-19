import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../core/error_translator.dart';
import '../models/consumption_response_model.dart';
import '../models/consumption_stats_model.dart';
import '../models/device_model.dart';
import '../models/meter_model.dart';
import '../models/module_iot_model.dart';
import '../models/paginated_readings_response.dart';
import '../models/reading_model.dart';
import '../models/reading_request_model.dart';
import '../models/recharge_request_model.dart';
import '../models/user_profile_model.dart';

class MeterService {
  static const String _baseUrl = AppConfig.baseUrl;
  static const String _compteursUrl = '$_baseUrl/compteurs';
  static const String _readingsUrl = '$_baseUrl/readings';
  static const String _devicesUrl = '$_baseUrl/devices';
  static const String _moduleDevicesUrl = '$_baseUrl/module-devices';
  static const String _usersUrl = '$_baseUrl/users';

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

  Exception _handleError(http.Response response) =>
      ErrorTranslator.fromResponse(response);

  Future<List<MeterModel>> getMesCompteurs() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(_compteursUrl), headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Gère réponse wrappée {"status":200,"data":[...]} et liste directe
      final List<dynamic> jsonData = decoded is List
          ? decoded
          : (decoded['data'] ?? decoded['content'] ?? []) as List<dynamic>;
      return jsonData.map((e) => MeterModel.fromJson(e)).toList();
    }
    throw _handleError(response);
  }

  /// GET /api/compteurs/{id}/stats
  Future<ConsumptionStatsModel> getCompteurStats(int compteurId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_compteursUrl/$compteurId/stats'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final rawData = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      if (rawData == null) return ConsumptionStatsModel();
      return ConsumptionStatsModel.fromJson(rawData as Map<String, dynamic>);
    }
    throw _handleError(response);
  }

  /// GET /api/readings/meters/{meterId}/latest
  Future<ReadingModel?> getLatestReading(int meterId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_readingsUrl/meters/$meterId/latest'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.isEmpty || body == 'null') return null;
      final decoded = json.decode(body);
      debugPrint('LATEST READING RESPONSE: $decoded');
      final data = decoded is Map && decoded.containsKey('data') && decoded['data'] != null
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;
      return ReadingModel.fromJson(data);
    }
    if (response.statusCode == 404) return null;
    throw _handleError(response);
  }

  /// GET /api/readings/meters/{meterId}?page=0&size=20
  Future<PaginatedReadingsResponse> getReadingsByMeter(
    int meterId, {
    int page = 0,
    int size = 50,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_readingsUrl/meters/$meterId').replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Gère BaseResponse<Page> {"data":{content:[...]}} et Page directe {content:[...]}
      final Map<String, dynamic> data;
      if (decoded is Map && decoded.containsKey('data') && decoded['data'] is Map) {
        data = decoded['data'] as Map<String, dynamic>;
      } else if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        data = const {};
      }
      return PaginatedReadingsResponse.fromJson(data);
    }
    throw _handleError(response);
  }

  Future<MeterModel> getCompteurById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_compteursUrl/$id'), headers: headers);
    if (response.statusCode == 200) {
      return MeterModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<MeterModel> createCompteur({
    required String reference,
    required String adresse,
    required String typeCompteur,
    required double valeurInitiale,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(_compteursUrl),
      headers: headers,
      body: json.encode({
        'reference': reference,
        'adresse': adresse,
        'typeCompteur': typeCompteur,
        'valeurInitiale': valeurInitiale,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return MeterModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<MeterModel> configureModeLecture(
    int compteurId, {
    required String modeLecture,
    String? commentaire,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_compteursUrl/$compteurId/mode-lecture'),
      headers: headers,
      body: json.encode({
        'modeLecture': modeLecture,
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
      }),
    );
    if (response.statusCode == 200) {
      try {
        return MeterModel.fromJson(json.decode(response.body));
      } on FormatException {
        // Le backend renvoie parfois du texte brut au lieu de JSON
        // (ex: "Compteur X configuré en mode Y") — on crée un modèle minimal.
        return MeterModel(
          id: compteurId,
          reference: '',
          adresse: '',
          typeCompteur: '',
          valeurActuelle: 0,
          statut: 'CONFIGURE',
          modeLectureConfigure: modeLecture,
          proprietaireEmail: '',
          proprietaireId: 0,
          actif: true,
        );
      }
    }
    throw _handleError(response);
  }

  Future<void> reinitialiserCompteur(
    int compteurId, {
    required String motif,
    String? commentaire,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_compteursUrl/$compteurId/reinitialiser'),
      headers: headers,
      body: json.encode({
        'motif': motif,
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
      }),
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  Future<ReadingModel> ajouterReleve(ReadingRequestModel request) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_readingsUrl/manual'),
      headers: headers,
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReadingModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<PaginatedReadingsResponse> getHistoriqueReleves(
    int compteurId, {
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int size = 20,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'page': '$page',
      'size': '$size',
    };
    if (startDate != null) {
      queryParams['startDate'] = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    if (endDate != null) {
      queryParams['endDate'] = '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    final uri = Uri.parse('$_readingsUrl/historique/$compteurId').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return PaginatedReadingsResponse.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<ReadingModel?> getDernierReleve(int compteurId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_readingsUrl/latest/$compteurId'), headers: headers);
    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty || response.body.trim() == 'null') return null;
      return ReadingModel.fromJson(json.decode(response.body));
    }
    if (response.statusCode == 404) return null;
    throw _handleError(response);
  }

  Future<MeterModel> rechargerCompteur(RechargeRequestModel request) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_compteursUrl/recharger'),
      headers: headers,
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return MeterModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<ConsumptionStatsModel> getStatistiques(int compteurId, {String periode = 'mois'}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_compteursUrl/$compteurId/statistiques').replace(queryParameters: {'periode': periode});
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return ConsumptionStatsModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<ConsumptionResponseModel> getConsommation(int compteurId, {DateTime? startDate, DateTime? endDate}) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    if (endDate != null) {
      queryParams['endDate'] = '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    final uri = Uri.parse('$_compteursUrl/$compteurId/consommation').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return ConsumptionResponseModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<DeviceModel> scanDevice({required String qrCode, required int userId}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_devicesUrl/scan'),
      headers: headers,
      body: json.encode({'qrCode': qrCode, 'userId': userId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return DeviceModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<DeviceModel> associateDevice({required String deviceCode, required int compteurId, required int captureInterval}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_devicesUrl/$deviceCode/associate'),
      headers: headers,
      body: json.encode({'compteurId': compteurId, 'captureInterval': captureInterval}),
    );
    if (response.statusCode == 200) {
      return DeviceModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<DeviceModel> getDeviceStatus(String deviceCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_devicesUrl/$deviceCode/status'), headers: headers);
    if (response.statusCode == 200) {
      return DeviceModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<List<DeviceModel>> getMyDevices() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_devicesUrl/my'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => DeviceModel.fromJson(json)).toList();
    }
    throw _handleError(response);
  }

  Future<void> updateCaptureInterval({required String deviceCode, required int interval}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_devicesUrl/$deviceCode/capture-interval').replace(queryParameters: {'interval': '$interval'});
    final response = await http.put(uri, headers: headers);
    if (response.statusCode != 200) throw _handleError(response);
  }

  Future<ReadingModel> createSensorReading({required int compteurId, required double valeur, required String deviceCode, String? commentaire}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_readingsUrl/sensor'),
      headers: headers,
      body: json.encode({
        'compteurId': compteurId,
        'valeur': valeur,
        'deviceCode': deviceCode,
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReadingModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  Future<ReadingModel> uploadReading({required String filePath, required String deviceCode, String? commentaire}) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$_readingsUrl/upload'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields['deviceCode'] = deviceCode;
    if (commentaire != null && commentaire.isNotEmpty) {
      request.fields['commentaire'] = commentaire;
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReadingModel.fromJson(json.decode(response.body));
    }
    throw _handleError(response);
  }

  /// GET /api/users/profile — retourne le profil complet de l'utilisateur connecté
  Future<UserProfileModel> getUserProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_usersUrl/profile'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // BaseResponse<UserProfileDTO> → extraire le champ 'data'
      final data = decoded is Map && decoded.containsKey('data') && decoded['data'] != null
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;
      return UserProfileModel.fromJson(data);
    }
    throw _handleError(response);
  }

  /// GET /api/module-devices/my — retourne le premier module actif de l'utilisateur, ou null
  Future<ModuleIotModel?> getMyModule() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_moduleDevicesUrl/my'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded['data'] ?? decoded['content'] ?? []) as List<dynamic>;
      if (list.isEmpty) return null;
      // Préférer le premier module ACTIF, sinon le premier de la liste
      final actif = list.cast<Map<String, dynamic>>().firstWhere(
            (m) => m['statut']?.toString().toUpperCase() == 'ACTIF',
            orElse: () => list.first as Map<String, dynamic>,
          );
      return ModuleIotModel.fromJson(actif);
    }
    if (response.statusCode == 404) return null;
    throw _handleError(response);
  }

  /// PUT /api/users/seuils?seuilCredit=&seuilAnomalie= — met à jour les seuils d'alerte
  Future<void> updateSeuils({
    required double seuilCredit,
    required double seuilAnomalie,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_usersUrl/seuils').replace(
      queryParameters: {
        'seuilCredit': '$seuilCredit',
        'seuilAnomalie': '$seuilAnomalie',
      },
    );
    final response = await http.put(uri, headers: headers);
    if (response.statusCode != 200) throw _handleError(response);
  }

  /// PUT /api/users/notifications?push=&sms=&email= — met à jour les préférences de notification
  /// Seuls les paramètres non-null sont envoyés (required=false côté backend)
  Future<void> updateNotifications({
    bool? push,
    bool? sms,
    bool? email,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_usersUrl/notifications').replace(
      queryParameters: {
        if (push != null) 'push': '$push',
        if (sms != null) 'sms': '$sms',
        if (email != null) 'email': '$email',
      },
    );
    final response = await http.put(uri, headers: headers);
    if (response.statusCode != 200) throw _handleError(response);
  }
}


