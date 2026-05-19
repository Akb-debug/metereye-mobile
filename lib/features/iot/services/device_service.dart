import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import '../models/device_associate_request.dart';
import '../models/device_scan_request.dart';
import '../models/iot_module_response.dart';

class DeviceService {
  /// POST /api/devices/scan — retourne le deviceCode reconnu par le backend
  Future<String> scanDevice(String token, DeviceScanRequest request) async {
    final res = await http
        .post(
          Uri.parse(AppConfig.devicesScanUrl),
          headers: _headers(token),
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    _assertOk(res, 'QR Code non reconnu par le serveur');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Le backend peut renvoyer deviceCode ou qrCode selon l'implementation
    return data['deviceCode']?.toString() ??
        data['qrCode']?.toString() ??
        request.qrCode;
  }

  /// POST /api/devices/{deviceCode}/associate
  Future<IotModuleResponse> associateDevice(
    String token,
    String deviceCode,
    DeviceAssociateRequest request,
  ) async {
    final res = await http
        .post(
          Uri.parse('${AppConfig.devicesBaseUrl}/$deviceCode/associate'),
          headers: _headers(token),
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    _assertOk(res, 'Erreur lors de l\'association du module');
    return IotModuleResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
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
      msg = body['message']?.toString() ?? defaultMsg;
    } catch (_) {}
    throw Exception(_mapCode(res.statusCode, msg));
  }

  String _mapCode(int code, String fallback) => switch (code) {
        400 => 'QR Code invalide ou module inconnu',
        401 => 'Session expiree, reconnectez-vous',
        403 => 'Vous n\'etes pas autorise a associer ce module',
        404 => 'Module non trouve — verifiez le QR Code',
        409 => 'Ce module est deja associe a un compteur',
        _   => fallback,
      };
}
