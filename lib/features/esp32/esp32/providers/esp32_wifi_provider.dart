import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../services/esp32_wifi_service.dart';

enum ESP32ConnectionStatus {
  unknown,
  checking,
  connected,
  disconnected,
  notConfigured,
}

class ESP32WifiProvider extends ChangeNotifier {
  final ESP32WifiService _service = ESP32WifiService();
  
  ESP32ConnectionStatus _status = ESP32ConnectionStatus.unknown;
  String? _esp32Ip;
  String? _error;
  bool _isCapturing = false;
  CaptureResponse? _lastCapture;
  
  ESP32ConnectionStatus get status => _status;
  String? get esp32Ip => _esp32Ip;
  String? get error => _error;
  bool get isConnected => _status == ESP32ConnectionStatus.connected;
  bool get isConfigured => _service.isConfigured;
  bool get isCapturing => _isCapturing;
  CaptureResponse? get lastCapture => _lastCapture;
  
  /// Initialise le provider en chargeant la config et tente reconnexion auto
  Future<void> initialize() async {
    await _service.loadConfig();
    _esp32Ip = _service.esp32Ip;
    
    if (!isConfigured) {
      _status = ESP32ConnectionStatus.notConfigured;
      notifyListeners();
      return;
    }
    
    // Tentative silencieuse de reconnexion (sans loader visible)
    _status = ESP32ConnectionStatus.checking;
    notifyListeners();
    
    final isConnected = await _service.testConnection();
    
    _status = isConnected 
        ? ESP32ConnectionStatus.connected 
        : ESP32ConnectionStatus.disconnected;
    
    if (!isConnected) {
      _error = 'ESP32 inaccessible. Vérifiez qu\'il est allumé.';
    }
    
    notifyListeners();
  }
  
  /// Met à jour l'IP automatiquement (appelé quand BLE détecte nouvelle IP)
  Future<void> updateIpFromBle(String newIp) async {
    if (_esp32Ip != newIp) {
      await _service.saveConfig(newIp);
      _esp32Ip = newIp;
      _error = null;
      notifyListeners();
      // On teste immédiatement si l'IP est joignable via WiFi
      await checkConnection();
    }
  }
  
  /// Vérifie si l'ESP32 est accessible
  Future<void> checkConnection() async {
    if (!isConfigured) {
      _status = ESP32ConnectionStatus.notConfigured;
      notifyListeners();
      return;
    }
    
    _status = ESP32ConnectionStatus.checking;
    _error = null;
    notifyListeners();
    
    final isConnected = await _service.testConnection();
    
    _status = isConnected 
        ? ESP32ConnectionStatus.connected 
        : ESP32ConnectionStatus.disconnected;
    
    if (!isConnected) {
      _error = 'ESP32 inaccessible à $_esp32Ip';
    }
    
    notifyListeners();
  }
  
  /// Configure l'IP de l'ESP32 et teste la connexion
  Future<void> configure(String ip, {int port = 80}) async {
    await _service.saveConfig(ip, port: port);
    _esp32Ip = ip;
    await checkConnection();
  }
  
  /// Sauvegarde l'IP sans tester la connexion (pour config rapide BLE)
  Future<void> saveIpOnly(String ip, {int port = 80}) async {
    await _service.saveConfig(ip, port: port);
    _esp32Ip = ip;
    _status = ESP32ConnectionStatus.connected; // On fait confiance à BLE
    _error = null;
    notifyListeners();
  }
  
  /// Supprime la configuration
  Future<void> clearConfiguration() async {
    await _service.clearConfig();
    _esp32Ip = null;
    _status = ESP32ConnectionStatus.notConfigured;
    _error = null;
    notifyListeners();
  }
  
  /// Déclenche une capture
  Future<void> triggerCapture() async {
    if (!isConnected) {
      // Tentative de reconnexion silencieuse avant d'échouer
      await checkConnection();
      if (!isConnected) {
        _error = 'ESP32 non connecté. Vérifiez qu\'il est allumé.';
        notifyListeners();
        return;
      }
    }
    
    _isCapturing = true;
    _error = null;
    notifyListeners();
    
    final response = await _service.triggerCapture();
    _lastCapture = response;
    _isCapturing = false;
    
    if (!response.success) {
      _error = response.message;
      // Si erreur de connexion, marquer comme déconnecté
      if (response.message.contains('connexion') || 
          response.message.contains('accessible') ||
          response.message.contains('non configuré')) {
        _status = ESP32ConnectionStatus.disconnected;
      }
    }
    
    notifyListeners();
  }
  
  /// Vérifie si l'ESP32 est toujours accessible (ping silencieux)
  Future<bool> ping() async {
    if (!isConfigured) return false;
    return await _service.testConnection();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearLastCapture() {
    _lastCapture = null;
    notifyListeners();
  }

  Future<Uint8List?> takeSnapshot() async {
    if (!isConnected) {
      await checkConnection();
      if (!isConnected) {
        _error = 'ESP32 non connecté.';
        notifyListeners();
        return null;
      }
    }

    _isCapturing = true;
    _error = null;
    notifyListeners();

    try {
      final bytes = await _service.takeSnapshot();
      _isCapturing = false;
      notifyListeners();
      return bytes;
    } catch (e) {
      _isCapturing = false;
      _error = e.toString();
      _status = ESP32ConnectionStatus.disconnected;
      notifyListeners();
      return null;
    }
  }
}
