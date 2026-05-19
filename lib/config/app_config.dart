class AppConfig {
  static const String androidUrl = 'http://localhost:8080/api';
  static const String phoneUrl = 'http://10.0.203.7:8080/api';
  static const String baseUrl = phoneUrl;

  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register';
  static const String profileUrl = '$baseUrl/users/profile';
  static const String compteursUrl = '$baseUrl/compteurs';
  static const String relevesUrl = '$baseUrl/readings/manual';
  static const String moduleDevicesUrl = '$baseUrl/module-devices';

  // IoT Modules (PZEM + ESP32)
  static const String iotModulesUrl = '$baseUrl/iot/modules';
  static const String devicesScanUrl = '$baseUrl/devices/scan';
  static const String devicesBaseUrl = '$baseUrl/devices';
  // URL envoyée au module PZEM/Raspberry via BLE — relevés numériques JSON
  static const String iotReadingsUrl = '$baseUrl/iot/readings';
  // URL envoyée au module ESP32-CAM via BLE — images multipart pour OCR
  static const String iotImageUrl = '$baseUrl/iot/image';

  // Seuils d'alerte affichés dans l'UI (valeurs par défaut côté Flutter)
  static const double defaultSeuilCreditFaible = 200.0;
  static const double defaultSeuilAnomalie = 50.0;

  // Mapping clé switch UI → paramètre backend de l'endpoint PUT /users/notifications
  static const Map<String, String> switchToNotifKey = {
    'creditFaible': 'push',
    'coupureIminente': 'sms',
    'rapportHebdo': 'email',
  };
}
