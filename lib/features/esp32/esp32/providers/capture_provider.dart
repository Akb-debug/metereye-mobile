import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../providers/data_sync_notifier.dart';
import '../services/esp32_api_service.dart';

class CaptureProvider extends ChangeNotifier {
  final DataSyncNotifier? _sync;

  CaptureProvider({DataSyncNotifier? sync}) : _sync = sync;

  bool _isCapturing = false;
  bool _isProcessing = false;
  CaptureResult? _lastResult;
  File? _capturedImage;
  String? _error;

  bool get isCapturing => _isCapturing;
  bool get isProcessing => _isProcessing;
  CaptureResult? get lastResult => _lastResult;
  File? get capturedImage => _capturedImage;
  String? get error => _error;

  Future<void> triggerCapture(String deviceId) async {
    _isCapturing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ESP32ApiService.triggerCapture(deviceId);
      _lastResult = result;
      
      if (!result.success) {
        _error = result.message;
      }
    } catch (e) {
      _error = 'Erreur de capture: $e';
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }

  Future<void> uploadImage(File imageFile) async {
    _isProcessing = true;
    _error = null;
    _capturedImage = imageFile;
    notifyListeners();

    try {
      final result = await ESP32ApiService.uploadImage(imageFile);
      _lastResult = result;

      if (result.success) {
        _sync?.notifyReadingAdded();
      } else {
        _error = result.message;
      }
    } catch (e) {
      _error = 'Erreur de traitement: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clear() {
    _lastResult = null;
    _capturedImage = null;
    _error = null;
    notifyListeners();
  }
}
