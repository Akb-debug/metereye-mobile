import 'package:flutter/material.dart';
import '../../esp32/esp32/providers/ble_provider.dart';
import '../models/bluetooth_provisioning_payload.dart';

enum ProvisioningPhase { idle, scanning, connecting, sending, done, error }

class BluetoothProvisioningProvider extends ChangeNotifier {
  final BleProvider _ble = BleProvider();
  ProvisioningPhase _phase = ProvisioningPhase.idle;
  String? _provisioningError;

  BluetoothProvisioningProvider() {
    _ble.addListener(_mirrorBleState);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  ProvisioningPhase get phase => _phase;
  bool get isScanning => _ble.state == BleState.scanning;
  bool get isConnected => _ble.isConnected;
  bool get isDone => _phase == ProvisioningPhase.done;
  bool get isSending => _phase == ProvisioningPhase.sending;

  List<BleDevice> get devices => _ble.devices;
  BleDevice? get connectedDevice => _ble.connectedDevice;
  String? get connectedIp => _ble.wifiIp;
  String? get error => _provisioningError ?? _ble.error;

  // ── BLE delegation ────────────────────────────────────────────────────────

  Future<void> startScan() => _ble.startScan();
  Future<void> stopScan() => _ble.stopScan();

  Future<bool> connect(BleDevice device) async {
    _phase = ProvisioningPhase.connecting;
    notifyListeners();
    return _ble.connect(device);
  }

  Future<void> disconnect() => _ble.disconnect();

  // ── Provisioning ──────────────────────────────────────────────────────────

  /// Envoie le payload complet au module via BLE
  Future<bool> sendProvisioning(BluetoothProvisioningPayload payload) async {
    _phase = ProvisioningPhase.sending;
    _provisioningError = null;
    notifyListeners();

    final success = await _ble.sendRawConfig(payload.toJson());

    _phase = success ? ProvisioningPhase.done : ProvisioningPhase.error;
    if (!success) {
      _provisioningError =
          _ble.error ?? 'Echec de la configuration — reessayez';
    }
    notifyListeners();
    return success;
  }

  void clearError() {
    _provisioningError = null;
    _ble.clearError();
    if (_phase == ProvisioningPhase.error) _phase = ProvisioningPhase.idle;
    notifyListeners();
  }

  // ── Interne ───────────────────────────────────────────────────────────────

  void _mirrorBleState() {
    switch (_ble.state) {
      case BleState.scanning:
        _phase = ProvisioningPhase.scanning;
      case BleState.connecting:
        _phase = ProvisioningPhase.connecting;
      case BleState.error:
        if (_phase != ProvisioningPhase.sending) {
          _phase = ProvisioningPhase.error;
          _provisioningError = _ble.error;
        }
      default:
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ble.removeListener(_mirrorBleState);
    _ble.dispose();
    super.dispose();
  }
}
