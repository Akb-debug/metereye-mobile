import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../config/app_config.dart';

/// Service pour gérer la liaison ESP32 ↔ Utilisateur
class EspLinkingService {
  final Dio _dio;
  
  EspLinkingService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  /// Vérifie si l'utilisateur a un ESP32 lié (local + backend)
  Future<EspLinkingStatus> checkLinkedEsp(String token) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Vérifier local d'abord
    final linkedUuid = prefs.getString('linked_esp_uuid');
    final linkedIp = prefs.getString('linked_esp_ip');
    
    if (linkedUuid == null || linkedIp == null) {
      return EspLinkingStatus.notLinked();
    }
    
    try {
      // Vérifier avec le backend si le device existe toujours
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/api/devices/my-device');
      
      if (response.statusCode == 200) {
        final data = response.data;
        return EspLinkingStatus.linked(
          uuid: data['uuid'] ?? linkedUuid,
          ip: data['ipAddress'] ?? linkedIp,
          compteurId: prefs.getInt('linked_compteur_id'),
          isOnline: data['status'] == 'ONLINE',
        );
      }
    } catch (e) {
      debugPrint('Backend check failed, using local: $e');
    }
    
    // Fallback sur les données locales
    return EspLinkingStatus.linked(
      uuid: linkedUuid,
      ip: linkedIp,
      compteurId: prefs.getInt('linked_compteur_id'),
      isOnline: null, // Status inconnu
    );
  }
  
  /// Récupère l'IP sauvegardée
  Future<String?> getSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('linked_esp_ip');
  }
  
  /// Sauvegarde manuelle (si besoin)
  Future<void> saveLinkedEsp(String uuid, String ip, int compteurId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_esp_uuid', uuid);
    await prefs.setString('linked_esp_ip', ip);
    await prefs.setInt('linked_compteur_id', compteurId);
  }
  
  /// Met à jour l'IP (si DHCP change)
  Future<void> updateIp(String newIp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_esp_ip', newIp);
  }
  
  /// Supprime le linking (déconnexion)
  Future<void> clearLinkedEsp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('linked_esp_uuid');
    await prefs.remove('linked_esp_ip');
    await prefs.remove('linked_compteur_id');
  }
}

/// Statut de liaison ESP32
class EspLinkingStatus {
  final bool isLinked;
  final String? uuid;
  final String? ip;
  final int? compteurId;
  final bool? isOnline;
  
  EspLinkingStatus._({
    required this.isLinked,
    this.uuid,
    this.ip,
    this.compteurId,
    this.isOnline,
  });
  
  factory EspLinkingStatus.notLinked() => EspLinkingStatus._(isLinked: false);
  
  factory EspLinkingStatus.linked({
    required String uuid,
    required String ip,
    int? compteurId,
    bool? isOnline,
  }) => EspLinkingStatus._(
    isLinked: true,
    uuid: uuid,
    ip: ip,
    compteurId: compteurId,
    isOnline: isOnline,
  );
}
