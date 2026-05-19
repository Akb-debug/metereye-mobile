import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Callback quand l'ESP32 est déjà connecté au WiFi
typedef OnAlreadyConnectedCallback = void Function(String ip);

/// Animation controller externe pour l'icône Bluetooth
typedef OnScanningAnimationCallback = void Function(bool isScanning);

// UUIDs ESP32
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

enum BleState {
  idle,
  scanning,
  connecting,
  connected,
  configuring,
  configured,
  error,
}

class BleDevice {
  final String id;
  final String name;
  final BluetoothDevice device;
  BleDevice({required this.id, required this.name, required this.device});
}

class BleProvider extends ChangeNotifier {
  bool _isDisposed = false;
  BleState _state = BleState.idle;
  List<BleDevice> _devices = [];
  BleDevice? _connectedDevice;
  BluetoothCharacteristic? _char;
  String? _uuid;
  String? _error;
  String? _wifiStatus;
  
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanup();
    super.dispose();
  }
  String? _wifiIp;
  List<String> _wifiNetworks = [];
  bool _isScanningWiFi = false;
  
  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;

  // Getters
  BleState get state => _state;
  List<BleDevice> get devices => _devices;
  BleDevice? get connectedDevice => _connectedDevice;
  String? get uuid => _uuid;
  String? get error => _error;
  bool get isConnected => _state == BleState.connected || _state == BleState.configuring || _state == BleState.configured;
  bool get isConfiguring => _state == BleState.configuring;
  String? get wifiStatus => _wifiStatus;
  String? get wifiIp => _wifiIp;
  List<String> get wifiNetworks => _wifiNetworks;
  bool get isScanningWiFi => _isScanningWiFi;
  bool get isBluetoothOff => FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off;

  // Callbacks
  OnAlreadyConnectedCallback? onAlreadyConnected;
  OnScanningAnimationCallback? onScanningAnimation;

  /// Déclenche une capture sur l'ESP32-CAM
  Future<bool> triggerCapture() async {
    if (_char == null || !isConnected) {
      _error = 'ESP32 non connecté';
      notifyListeners();
      return false;
    }

    try {
      final data = jsonEncode({'cmd': 'capture'});
      await _char!.write(utf8.encode(data));
      return true;
    } catch (e) {
      _error = 'Erreur envoi commande: $e';
      notifyListeners();
      return false;
    }
  }

  /// Définit les callbacks
  void setCallbacks({
    OnAlreadyConnectedCallback? onAlreadyConnected,
    OnScanningAnimationCallback? onScanningAnimation,
  }) {
    this.onAlreadyConnected = onAlreadyConnected;
    this.onScanningAnimation = onScanningAnimation;
  }

  // Scan
  Future<void> startScan() async {
    if (_state == BleState.scanning) return;

    // Vérifier si le Bluetooth est activé
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      _error = 'bluetooth_off';
      _state = BleState.error;
      notifyListeners();
      return;
    }

    _state = BleState.scanning;
    _devices = [];
    _error = null;
    notifyListeners();
    
    // Démarrer l'animation
    onScanningAnimation?.call(true);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          final name = r.device.advName;
          if (name.isEmpty) continue;
          if (!name.toUpperCase().contains('ESP32') && !name.toUpperCase().contains('METEREYE')) continue;
          
          final id = r.device.remoteId.toString();
          if (!_devices.any((d) => d.id == id)) {
            _devices.add(BleDevice(
              id: id,
              name: name.isNotEmpty ? name : 'ESP32-${id.substring(id.length - 4)}',
              device: r.device,
            ));
            notifyListeners();
          }
        }
      });

      await Future.delayed(const Duration(seconds: 10));
      await stopScan();
    } catch (e) {
      _setError('Scan error: $e');
    } finally {
      // Arrêter l'animation
      onScanningAnimation?.call(false);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    onScanningAnimation?.call(false);
    if (_state == BleState.scanning) {
      _state = BleState.idle;
      notifyListeners();
    }
  }

  // Connect
  Future<bool> connect(BleDevice device) async {
    if (_state == BleState.connecting) return false;
    
    _state = BleState.connecting;
    _error = null;
    notifyListeners();

    try {
      await device.device.connect(autoConnect: false);
      _connectedDevice = device;
      
      // Négocie une MTU plus large pour les payloads JSON avec JWT
      try {
        await device.device.requestMtu(512);
      } catch (_) {}

      // Discover services
      final services = await device.device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == SERVICE_UUID) {
          for (var c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == CHAR_UUID) {
              _char = c;
              break;
            }
          }
          break;
        }
      }

      if (_char == null) {
        throw Exception('BLE characteristic not found');
      }

      // Activer les notifications pour recevoir les mises à jour
      await _char!.setNotifyValue(true);
      
      // Écouter les notifications pour détecter le statut WiFi
      _connSub = _char!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final str = utf8.decode(value);
        _processNotification(str);
      });

      // Read initial value - contient généralement l'UUID
      final val = await _char!.read();
      if (val.isNotEmpty) {
        final rawData = utf8.decode(val);
        _processInitialValue(rawData);
      }
      
      // Demander explicitement le statut WiFi actuel
      // L'ESP32 répondra avec {"status":"connected","ip":"..."} ou {"status":"disconnected"}
      final statusRequest = jsonEncode({'cmd': 'get_status'});
      await _char!.write(utf8.encode(statusRequest));
      
      // Attendre un peu la réponse
      await Future.delayed(const Duration(milliseconds: 500));

      // Si pas encore configuré (pas reçu de status=connected), passer à connected
      if (_state != BleState.configured) {
        _state = BleState.connected;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Connect error: $e');
      return false;
    }
  }

  /// Scan les réseaux WiFi disponibles via l'ESP32
  Future<void> scanWiFiNetworks() async {
    if (_char == null || !isConnected) {
      _setError('ESP32 non connecté');
      return;
    }

    _isScanningWiFi = true;
    _wifiNetworks = [];
    notifyListeners();

    StreamSubscription? sub;
    
    try {
      // Activer les notifications pour recevoir la réponse
      await _char!.setNotifyValue(true);
      
      // Écouter la réponse (sera traitée par _processNotification)
      sub = _char!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final str = utf8.decode(value);
        _processNotification(str);
      });

      // Envoyer commande de scan
      final data = jsonEncode({'cmd': 'scan_wifi'});
      debugPrint('Sending scan_wifi command...');
      await _char!.write(utf8.encode(data));

      // Attendre la réponse (timeout 10s)
      await Future.delayed(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('WiFi scan error: $e');
    } finally {
      sub?.cancel();
      _isScanningWiFi = false;
      notifyListeners();
    }
  }

  // Configure WiFi + API backend
  Future<bool> configureWiFi(
    String ssid,
    String password, {
    String? backendUrl,
    String? token,
    int? compteurId,
  }) async {
    if (_char == null || _connectedDevice == null) {
      _setError('Not connected');
      return false;
    }

    _state = BleState.configuring;
    _wifiStatus = null;
    _wifiIp = null;
    notifyListeners();

    final completer = Completer<bool>();
    StreamSubscription? sub;

    try {
      // Enable notifications
      await _char!.setNotifyValue(true);

      // Listen for response
      sub = _char!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final str = utf8.decode(value);
        // Ignorer les messages non-JSON (ex: UUID en texte brut)
        if (!str.trim().startsWith('{')) {
          debugPrint('Non-JSON message ignored: $str');
          return;
        }
        try {
          final resp = jsonDecode(str);
          debugPrint('ESP32 response: $resp');

          final status = resp['status'] as String?;
          _wifiStatus = status;

          // Réception des réseaux WiFi scannés
          if (status == 'wifi_list') {
            final networks = resp['networks'] as List<dynamic>?;
            if (networks != null) {
              _wifiNetworks = networks.map((n) => n.toString()).toList();
              _isScanningWiFi = false;
              notifyListeners();
            }
            return;
          }

          if (status == 'connected') {
            _wifiIp = resp['ip'] as String?;
            _state = BleState.configured;
            if (!completer.isCompleted) completer.complete(true);
          } else if (status == 'failed' || status == 'error') {
            _state = BleState.connected;
            if (!completer.isCompleted) completer.complete(false);
          }
          notifyListeners();
        } catch (e) {
          debugPrint('Parse error: $e');
        }
      });

      // Construire le payload — inclure la config API si disponible
      final Map<String, dynamic> payload = {'ssid': ssid, 'password': password};
      if (backendUrl != null && backendUrl.isNotEmpty) payload['backendUrl'] = backendUrl;
      if (token != null && token.isNotEmpty) payload['token'] = token;
      if (compteurId != null && compteurId > 0) payload['compteurId'] = compteurId;
      final data = jsonEncode(payload);
      await _char!.write(utf8.encode(data));

      // Wait for response
      return await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          _state = BleState.connected;
          _error = 'Timeout - check WiFi password';
          notifyListeners();
          return false;
        },
      );
    } catch (e) {
      _setError('WiFi config error: $e');
      _state = BleState.connected;
      return false;
    } finally {
      await sub?.cancel();
    }
  }

  /// Envoie un payload JSON arbitraire via BLE et attend la reponse du module.
  /// Accepte status=connected, config_ok comme succes.
  Future<bool> sendRawConfig(Map<String, dynamic> payload) async {
    if (_char == null || _connectedDevice == null) {
      _setError('Non connecte');
      return false;
    }

    _state = BleState.configuring;
    _wifiStatus = null;
    _wifiIp = null;
    notifyListeners();

    final completer = Completer<bool>();
    StreamSubscription? sub;

    try {
      await _char!.setNotifyValue(true);

      sub = _char!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final str = utf8.decode(value);
        if (!str.trim().startsWith('{')) return;
        try {
          final resp = jsonDecode(str) as Map<String, dynamic>;
          final status = resp['status'] as String?;
          _wifiStatus = status;

          if (status == 'connected' || status == 'config_ok') {
            _wifiIp = resp['ip'] as String?;
            _state = BleState.configured;
            if (!completer.isCompleted) completer.complete(true);
          } else if (status == 'failed' || status == 'error') {
            _state = BleState.connected;
            if (!completer.isCompleted) completer.complete(false);
          }
          notifyListeners();
        } catch (e) {
          debugPrint('sendRawConfig parse error: $e');
        }
      });

      final data = jsonEncode(payload);
      await _char!.write(utf8.encode(data));

      return await completer.future.timeout(
        const Duration(seconds: 40),
        onTimeout: () {
          _state = BleState.connected;
          _error = 'Timeout — verifiez que le module est allume et a portee';
          notifyListeners();
          return false;
        },
      );
    } catch (e) {
      _setError('Erreur envoi config: $e');
      _state = BleState.connected;
      return false;
    } finally {
      await sub?.cancel();
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.device.disconnect();
    } catch (_) {}
    _cleanup();
  }

  /// Traite les notifications BLE (réponses de l'ESP32)
  void _processNotification(String rawData) {
    debugPrint('BLE Notification: $rawData');
    
    if (!rawData.trim().startsWith('{')) return;
    
    try {
      final json = jsonDecode(rawData);
      final status = json['status'] as String?;
      final ip = json['ip'] as String?;
      
      if (status == 'connected' && ip != null && _state != BleState.configured) {
        // ESP32 connecté au WiFi
        _wifiStatus = 'connected';
        _wifiIp = ip;
        _state = BleState.configured;
        
        // Notifier pour redirection automatique
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onAlreadyConnected?.call(ip);
        });
        notifyListeners();
      } else if (status == 'disconnected' || status == 'failed') {
        _wifiStatus = status;
        notifyListeners();
      } else if (status == 'wifi_list') {
        // Liste des réseaux reçue
        final networks = json['networks'] as List<dynamic>?;
        if (networks != null) {
          _wifiNetworks = networks.map((n) => n.toString()).toList();
          _isScanningWiFi = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Notification parse error: $e');
    }
  }

  /// Traite la valeur initiale - peut être UUID ou JSON avec status
  void _processInitialValue(String rawData) {
    debugPrint('BLE Initial value: $rawData');
    
    // Essayer de parser comme JSON
    if (rawData.trim().startsWith('{')) {
      try {
        final json = jsonDecode(rawData);
        final status = json['status'] as String?;
        final ip = json['ip'] as String?;
        final uuid = json['uuid'] as String?;
        
        if (status == 'connected' && ip != null) {
          // ESP32 déjà connecté au WiFi
          _wifiStatus = 'connected';
          _wifiIp = ip;
          _uuid = uuid ?? _connectedDevice?.name ?? 'ESP32';
          _state = BleState.configured;
          
          // Notifier pour redirection automatique
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onAlreadyConnected?.call(ip);
          });
          return;
        }
      } catch (_) {
        // Pas du JSON valide, traiter comme UUID brut
      }
    }
    
    // Valeur simple (UUID ou nom) - tronquer si trop long
    _uuid = rawData.length > 30 ? '${rawData.substring(0, 27)}...' : rawData;
  }

  void _cleanup() {
    _connectedDevice = null;
    _char = null;
    _connSub?.cancel();
    _connSub = null;
    if (_state != BleState.idle && _state != BleState.error) {
      _state = BleState.idle;
      notifyListeners();
    }
  }

  void _setError(String msg) {
    _error = msg;
    _state = BleState.error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_state == BleState.error) {
      _state = BleState.idle;
      notifyListeners();
    }
  }
}
