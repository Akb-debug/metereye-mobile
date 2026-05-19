import 'package:flutter/material.dart';
import '../models/device_associate_request.dart';
import '../models/device_scan_request.dart';
import '../models/iot_module_request.dart';
import '../models/iot_module_response.dart';
import '../services/device_service.dart';
import '../services/iot_module_service.dart';

enum IotSetupStep { idle, loading, done, error }

class IotModuleProvider extends ChangeNotifier {
  final IotModuleService _moduleService;
  final DeviceService _deviceService;

  IotSetupStep _step = IotSetupStep.idle;
  IotModuleResponse? _module;
  String? _error;

  IotSetupStep get step => _step;
  IotModuleResponse? get module => _module;
  String? get error => _error;
  bool get isLoading => _step == IotSetupStep.loading;

  IotModuleProvider({
    IotModuleService? moduleService,
    DeviceService? deviceService,
  })  : _moduleService = moduleService ?? IotModuleService(),
        _deviceService = deviceService ?? DeviceService();

  /// Cree le module via formulaire — POST /api/iot/modules
  Future<bool> createModule(String token, IotModuleRequest request) async {
    _begin();
    try {
      _module = await _moduleService.createModule(token, request);
      _done();
      return true;
    } catch (e) {
      _fail(e.toString());
      return false;
    }
  }

  /// Scanne le QR code puis associe le module au compteur
  /// POST /api/devices/scan + POST /api/devices/{code}/associate
  Future<bool> scanAndAssociate({
    required String token,
    required int userId,
    required String qrCode,
    required int compteurId,
    int captureInterval = 60,
  }) async {
    _begin();
    try {
      final deviceCode = await _deviceService.scanDevice(
        token,
        DeviceScanRequest(qrCode: qrCode, userId: userId),
      );
      _module = await _deviceService.associateDevice(
        token,
        deviceCode,
        DeviceAssociateRequest(
            compteurId: compteurId, captureInterval: captureInterval),
      );
      _done();
      return true;
    } catch (e) {
      _fail(e.toString());
      return false;
    }
  }

  /// Rafraichit le statut du module — GET /api/iot/modules/{deviceCode}
  Future<void> refreshStatus(String token) async {
    if (_module == null) return;
    try {
      _module = await _moduleService.getModule(token, _module!.deviceCode);
      notifyListeners();
    } catch (_) {}
  }

  void reset() {
    _step = IotSetupStep.idle;
    _module = null;
    _error = null;
    notifyListeners();
  }

  void _begin() {
    _step = IotSetupStep.loading;
    _error = null;
    notifyListeners();
  }

  void _done() {
    _step = IotSetupStep.done;
    notifyListeners();
  }

  void _fail(String msg) {
    _error = msg;
    _step = IotSetupStep.error;
    notifyListeners();
  }
}
