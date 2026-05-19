import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour communiquer avec l'ESP32-CAM via WiFi
class ESP32WifiService {
  static const String _prefsKey = 'esp32_config';
  
  String? _esp32Ip;
  int _esp32Port = 80;
  
  String? get esp32Ip => _esp32Ip;
  bool get isConfigured => _esp32Ip != null;
  
  /// Charge la configuration sauvegardée
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _esp32Ip = prefs.getString('${_prefsKey}_ip');
    _esp32Port = prefs.getInt('${_prefsKey}_port') ?? 80;
  }
  
  /// Sauvegarde la configuration
  Future<void> saveConfig(String ip, {int port = 80}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsKey}_ip', ip);
    await prefs.setInt('${_prefsKey}_port', port);
    _esp32Ip = ip;
    _esp32Port = port;
  }
  
  /// Supprime la configuration
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefsKey}_ip');
    await prefs.remove('${_prefsKey}_port');
    _esp32Ip = null;
  }
  
  /// Teste la connexion avec l'ESP32
  Future<bool> testConnection() async {
    if (_esp32Ip == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('http://$_esp32Ip:$_esp32Port/status'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Déclenche une capture sur l'ESP32-CAM
  /// L'ESP32 capture et envoie directement au service OCR
  Future<Uint8List?> takeSnapshot() async {
    if (_esp32Ip == null) {
      throw Exception('ESP32 non configure');
    }
    
    try {
      final response = await http.get(
        Uri.parse('http://$_esp32Ip:$_esp32Port/snapshot'),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erreur ESP32: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<CaptureResponse> triggerCapture() async {
    if (_esp32Ip == null) {
      return CaptureResponse(
        success: false,
        message: 'ESP32 non configuré. Veuillez configurer l\'IP de l\'ESP32.',
      );
    }
    
    try {
      final response = await http.post(
        Uri.parse('http://$_esp32Ip:$_esp32Port/capture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'capture'}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CaptureResponse(
          success: true,
          message: data['message'] ?? 'Capture déclenchée',
          meterValue: data['meter_value'],
          confidence: data['confidence']?.toDouble(),
          imageUrl: data['image_url'],
        );
      } else {
        return CaptureResponse(
          success: false,
          message: 'Erreur ESP32: ${response.statusCode}',
        );
      }
    } catch (e) {
      return CaptureResponse(
        success: false,
        message: 'Erreur de connexion: $e\nVérifiez que l\'ESP32 est connecté au WiFi.',
      );
    }
  }
}

class CaptureResponse {
  final bool success;
  final String message;
  final String? meterValue;
  final double? confidence;
  final String? imageUrl;
  
  CaptureResponse({
    required this.success,
    required this.message,
    this.meterValue,
    this.confidence,
    this.imageUrl,
  });
}
