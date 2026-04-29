// 🔄 MODIFIÉ — app_config.dart — ajouts : seuilsUrl, notificationsUrl,
//   defaultSeuilCreditFaible, defaultSeuilAnomalie, switchToNotifKey

class AppConfig {
  static const String androidUrl = 'http://localhost:8080/api';
  static const String phoneUrl = 'http://10.0.116.104:8080/api';
  static const String baseUrl = phoneUrl;

  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register';
  static const String profileUrl = '$baseUrl/users/profile';
  static const String compteursUrl = '$baseUrl/compteurs';

  // Endpoints profil
  static const String seuilsUrl = '$baseUrl/users/seuils';
  static const String notificationsUrl = '$baseUrl/users/notifications';

  // Seuils alertes par défaut
  static const double defaultSeuilCreditFaible = 200.0;
  static const double defaultSeuilAnomalie = 50.0;

  // Mapping clé switch UI → paramètre backend notifications
  static const Map<String, String> switchToNotifKey = {
    'creditFaible': 'push',
    'coupureIminente': 'sms',
    'rapportHebdo': 'email',
  };
}
