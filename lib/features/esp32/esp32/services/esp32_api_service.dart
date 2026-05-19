import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ESP32ApiService {
  static const String _baseUrl = 'http://192.168.1.42:8000'; // IP du service OCR
  
  /// Déclenche une capture sur l'ESP32-CAM et récupère l'image
  static Future<CaptureResult> triggerCapture(String deviceId) async {
    try {
      // Appel au backend pour déclencher la capture ESP32
      final response = await http.post(
        Uri.parse('$_baseUrl/api/esp32/trigger-capture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CaptureResult(
          success: true,
          imageUrl: data['image_url'],
          meterValue: data['meter_value'],
          confidence: data['confidence']?.toDouble() ?? 0.0,
          message: data['message'] ?? 'Capture réussie',
        );
      } else {
        return CaptureResult(
          success: false,
          message: 'Erreur serveur: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      return CaptureResult(
        success: false,
        message: 'Erreur de connexion: vérifiez que le service OCR est démarré',
      );
    } catch (e) {
      return CaptureResult(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }

  /// Upload une image directement au service OCR pour test
  static Future<CaptureResult> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/ocr/read-meter'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return CaptureResult(
          success: data['success'] ?? false,
          meterValue: data['meter_value'],
          confidence: data['confidence']?.toDouble() ?? 0.0,
          rawText: data['raw_text'],
          message: data['message'] ?? 'Traitement terminé',
        );
      } else {
        return CaptureResult(
          success: false,
          message: 'Erreur OCR: ${response.statusCode}',
        );
      }
    } catch (e) {
      return CaptureResult(
        success: false,
        message: 'Erreur upload: $e',
      );
    }
  }
}

class CaptureResult {
  final bool success;
  final String? imageUrl;
  final String? meterValue;
  final double confidence;
  final String? rawText;
  final String message;

  CaptureResult({
    required this.success,
    this.imageUrl,
    this.meterValue,
    this.confidence = 0.0,
    this.rawText,
    required this.message,
  });
}
