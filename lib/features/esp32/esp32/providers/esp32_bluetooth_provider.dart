import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../../../../config/app_config.dart';

// UUIDs définis dans Config.h de l'ESP32-CAM
const String ESP32_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String ESP32_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String ESP32_DEVICE_NAME = "MeterEye-ESP32";

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  configuring,
  configured,
  error,
}

class BluetoothDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice device;

  BluetoothDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });
}

class Esp32BluetoothProvider extends ChangeNotifier {
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  List<BluetoothDeviceModel> _discoveredDevices = [];
  BluetoothDeviceModel? _connectedDevice;
  BluetoothCharacteristic? _wifiConfigCharacteristic;
  BluetoothCharacteristic? _qrCodeCharacteristic;

  bool _isScanning = false;
  bool _isConfiguring = false;
  bool _isScanningQr = false;
  String? _errorMessage;
  String? _receivedUuid; // UUID reçu depuis l'ESP32

  // Statut WiFi
  bool _isWifiConnected = false;
  String? _wifiIpAddress;
  String? _wifiStatus; // "connecting", "connected", "failed"

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  List<BluetoothDeviceModel> get discoveredDevices => _discoveredDevices;
  BluetoothDeviceModel? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected ||
      _connectionStatus == ConnectionStatus.configured;
  bool get isConfiguring => _isConfiguring;
  bool get isScanningQr => _isScanningQr;
  String? get errorMessage => _errorMessage;
  String? get receivedUuid => _receivedUuid;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;

  Future<void> initialize() async {
    // Vérifier si le Bluetooth est disponible et activé
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;

      if (adapterState == BluetoothAdapterState.unavailable) {
        _setError('Le Bluetooth n\'est pas disponible sur cet appareil');
        return;
      }

      if (adapterState != BluetoothAdapterState.on) {
        // Ne rien faire si Bluetooth désactivé - l'écran affichera la demande d'activation
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
        return;
      }

      // Démarrer le scan automatiquement
      await startScan();
    } catch (e) {
      _setError('Erreur d\'initialisation Bluetooth: $e');
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    // Demander les permissions Bluetooth au runtime (Android 12+ exige BLUETOOTH_SCAN)
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    if (!allGranted) {
      _setError('Permissions Bluetooth refusées. Autorisez le Bluetooth et la localisation dans les paramètres.');
      notifyListeners();
      return;
    }

    // Vérifier que le Bluetooth est activé avant de scanner
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
      return;
    }

    _isScanning = true;
    _discoveredDevices.clear();
    _connectionStatus = ConnectionStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      // Configurer le scan sans filtre de noms pour trouver tous les appareils
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      // Écouter les résultats
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (ScanResult result in results) {
            final device = result.device;
            final name = device.advName.isNotEmpty ? device.advName : 'ESP32-${device.remoteId.toString().substring(device.remoteId.toString().length - 4)}';

            // Ne garder que les appareils ESP32/MeterEye
            if (!name.toUpperCase().contains('ESP32') &&
                !name.toUpperCase().contains('METEREYE')) {
              continue;
            }

            // Vérifier si l'appareil est déjà dans la liste
            if (!_discoveredDevices.any((d) => d.id == device.remoteId.toString())) {
              _discoveredDevices.add(BluetoothDeviceModel(
                id: device.remoteId.toString(),
                name: name,
                rssi: result.rssi,
                device: device,
              ));
              notifyListeners();
            }
          }
        },
        onError: (error) {
          _setError('Erreur de scan: $error');
        },
      );

      // Arrêter le scan après le timeout
      await Future.delayed(const Duration(seconds: 15));
      await stopScan();
    } catch (e) {
      _setError('Erreur lors du scan: $e');
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du scan: $e');
    } finally {
      _isScanning = false;
      if (_connectionStatus == ConnectionStatus.scanning) {
        _connectionStatus = ConnectionStatus.disconnected;
      }
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDeviceModel deviceModel, {int retryCount = 0}) async {
    if (_connectionStatus == ConnectionStatus.connecting) return;

    _connectionStatus = ConnectionStatus.connecting;
    _errorMessage = null;
    _receivedUuid = null;
    notifyListeners();

    try {
      // Arrêter le scan
      await stopScan();

      final btDevice = deviceModel.device;
      debugPrint('=== ETAPE 1: Connexion BLE ===');

      // 1. Connexion simple sans MTU explicite
      await btDevice.connect(
        autoConnect: false,
      ).timeout(const Duration(seconds: 15));
      debugPrint('=== ETAPE 1: OK - Connexion établie ===');

      // 2. Attendre stabilisation
      await Future.delayed(const Duration(milliseconds: 2000));
      debugPrint('=== ETAPE 2: OK - Délai écoulé ===');

      // 3. Découvrir les services
      List<BluetoothService> services = [];
      try {
        debugPrint('=== ETAPE 3: Découverte services... ===');
        services = await btDevice.discoverServices().timeout(const Duration(seconds: 10));
        debugPrint('=== ETAPE 3: OK - ${services.length} services trouvés ===');
      } catch (e) {
        debugPrint('=== ETAPE 3: ERREUR $e - Retry ===');
        await Future.delayed(const Duration(milliseconds: 1000));
        services = await btDevice.discoverServices().timeout(const Duration(seconds: 10));
        debugPrint('=== ETAPE 3: OK au retry - ${services.length} services ===');
      }

      // 4. Trouver la caractéristique
      debugPrint('=== ETAPE 4: Recherche caractéristique ===');
      for (BluetoothService service in services) {
        debugPrint('  Service: ${service.uuid}');
        if (service.uuid.toString().toLowerCase() == ESP32_SERVICE_UUID.toLowerCase()) {
          debugPrint('  -> Service MeterEye trouvé!');
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            debugPrint('    Caractéristique: ${characteristic.uuid}');
            if (characteristic.uuid.toString().toLowerCase() == ESP32_CHARACTERISTIC_UUID.toLowerCase()) {
              _wifiConfigCharacteristic = characteristic;
              debugPrint('    -> Caractéristique WiFi trouvée!');
              break;
            }
          }
        }
      }

      if (_wifiConfigCharacteristic == null) {
        debugPrint('=== ERREUR: Caractéristique non trouvée! ===');
        throw Exception('Caractéristique WiFi non trouvée sur l\'ESP32');
      }

      // 5. Écouter la déconnexion
      debugPrint('=== ETAPE 5: Setup listener déconnexion ===');
      _connectionStateSubscription = btDevice.connectionState.listen((state) {
        debugPrint('État connexion BLE: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      _connectedDevice = deviceModel;
      _connectionStatus = ConnectionStatus.connected;
      debugPrint('=== ETAPE 5: OK - Status connecté ===');

      // 6. Lire l'UUID
      debugPrint('=== ETAPE 6: Lecture UUID ===');
      await Future.delayed(const Duration(milliseconds: 500));
      int readRetry = 0;
      while (readRetry < 3 && _receivedUuid == null) {
        try {
          final value = await _wifiConfigCharacteristic!.read().timeout(const Duration(seconds: 5));
          if (value.isNotEmpty) {
            _receivedUuid = utf8.decode(value);
            debugPrint('UUID lu: $_receivedUuid');
          }
        } catch (e) {
          readRetry++;
          debugPrint('Tentative $readRetry de lecture UUID échouée: $e');
          if (readRetry < 3) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }
      debugPrint('=== ETAPE 6: OK ===');

      notifyListeners();
      debugPrint('=== CONNEXION COMPLÈTE ===');
    } catch (e, stackTrace) {
      debugPrint('=== ERREUR CONNEXION: $e ===');
      debugPrint('Stack: $stackTrace');

      // Retry logic
      if (retryCount < 2) {
        debugPrint('Tentative de reconnexion ${retryCount + 1}/2...');
        await Future.delayed(const Duration(seconds: 1));
        await connectToDevice(deviceModel, retryCount: retryCount + 1);
        return;
      }

      _setError('Erreur de connexion: $e');
      _connectionStatus = ConnectionStatus.error;
      notifyListeners();

      // NE PAS déconnecter automatiquement - laisser l'utilisateur gérer
      debugPrint('Erreur finale - connexion non fermée automatiquement');
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.device.disconnect();
      }
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    } finally {
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _wifiConfigCharacteristic = null;
    _qrCodeCharacteristic = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connectionStatus = ConnectionStatus.disconnected;
    // Éviter l'erreur si déjà disposed
    try {
      notifyListeners();
    } catch (e) {
      // Provider déjà disposed, ignorer
      debugPrint('Provider déjà disposed, notification ignorée');
    }
  }

  Future<bool> configureWifi({
    required String ssid,
    required String password,
    required int compteurId,
    required String token,
  }) async {
    if (_wifiConfigCharacteristic == null || _connectedDevice == null) {
      _setError('Module ESP32 déconnecté. Veuillez vous reconnecter au Bluetooth.');
      return false;
    }

    // Vérifier que la connexion est toujours active
    final currentState = await _connectedDevice!.device.connectionState.first;
    if (currentState == BluetoothConnectionState.disconnected) {
      _setError('Connexion BLE perdue. Veuillez reconnecter l\'ESP32.');
      return false;
    }

    _isConfiguring = true;
    _connectionStatus = ConnectionStatus.configuring;
    _errorMessage = null;
    _wifiStatus = 'pending';
    notifyListeners();

    StreamSubscription? subscription;

    try {
      // 1. Activer les notifications AVANT d'envoyer les données
      await _wifiConfigCharacteristic!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 200));

      // 2. Préparer les données WiFi
      final wifiData = {
        'ssid': ssid,
        'password': password,
        'compteurId': compteurId,
        'backendUrl': AppConfig.baseUrl,
        'token': token,
      };

      final jsonData = jsonEncode(wifiData);
      final bytes = utf8.encode(jsonData);

      debugPrint('Envoi de ${bytes.length} bytes à l\'ESP32...');

      // 3. Écouter la réponse AVANT d'envoyer
      final completer = Completer<bool>();

      subscription = _wifiConfigCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          try {
            final response = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
            debugPrint('Réponse ESP32: $response');

            final status = response['status'] as String?;
            _wifiStatus = status;

            if (status == 'connected') {
              _isWifiConnected = true;
              _wifiIpAddress = response['ip'] as String?;
              _connectionStatus = ConnectionStatus.configured;
              _isConfiguring = false;
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            } else if (status == 'failed' || status == 'error' || status == 'rate_limited') {
              _isWifiConnected = false;
              _errorMessage = response['error'] as String? ?? 'Échec de connexion WiFi';
              _connectionStatus = ConnectionStatus.connected;
              _isConfiguring = false;
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            }
            // Si status est "connecting" ou "pending", on continue d'attendre

            notifyListeners();
          } catch (e) {
            debugPrint('Erreur parsing réponse ESP32: $e');
          }
        }
      });

      // 4. Envoyer les données avec write sans réponse pour éviter le timeout
      // L'ESP32 enverra la réponse via notification
      if (bytes.length > 512) {
        // Fragmenter en chunks de 512 bytes max
        for (int i = 0; i < bytes.length; i += 500) {
          final end = (i + 500 < bytes.length) ? i + 500 : bytes.length;
          final chunk = bytes.sublist(i, end);
          await _wifiConfigCharacteristic!.write(
            chunk,
            allowLongWrite: true,
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } else {
        await _wifiConfigCharacteristic!.write(bytes);
      }

      debugPrint('Données WiFi envoyées, attente de la réponse...');

      // 5. Attendre la réponse avec timeout (40 secondes max pour l'ESP32)
      final result = await completer.future.timeout(
        const Duration(seconds: 40),
        onTimeout: () {
          if (!completer.isCompleted) {
            _errorMessage = 'Timeout: pas de réponse de l\'ESP32 (vérifiez le mot de passe WiFi)';
            _isConfiguring = false;
            _connectionStatus = ConnectionStatus.connected;
            notifyListeners();
          }
          return false;
        },
      );

      return result;
    } catch (e) {
      _setError('Erreur lors de la configuration WiFi: $e');
      _isConfiguring = false;
      _connectionStatus = ConnectionStatus.connected;
      notifyListeners();
      return false;
    } finally {
      subscription?.cancel();
    }
  }

  Future<void> startQrCodeScan() async {
    _isScanningQr = true;
    _errorMessage = null;
    notifyListeners();

    // La logique de scan QR sera implémentée avec la caméra
    // Pour l'instant, simulons un scan réussi après 2 secondes
    await Future.delayed(const Duration(seconds: 2));

    _isScanningQr = false;
    notifyListeners();

    // Retourner un code QR simulé
    return;
  }

  Future<bool> associateDeviceWithCompteur({
    required String qrCode,
    required int compteurId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/devices/associate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qrCode': qrCode,
          'compteurId': compteurId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _setError('Erreur lors de l\'association: ${response.body}');
        return false;
      }
    } catch (e) {
      _setError('Erreur réseau: $e');
      return false;
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _connectionStatus = ConnectionStatus.error;
  }

  void clearError() {
    _errorMessage = null;
    if (_connectionStatus == ConnectionStatus.error) {
      _connectionStatus = ConnectionStatus.disconnected;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // 1. Annuler d'abord tous les listeners pour éviter callbacks après dispose
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    
    // 2. Déconnecter le device BLE sans trigger de callbacks
    try {
      if (_connectedDevice != null) {
        _connectedDevice!.device.disconnect().catchError((_) {});
      }
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    }
    
    _connectedDevice = null;
    _wifiConfigCharacteristic = null;
    _qrCodeCharacteristic = null;
    
    super.dispose();
  }
}
