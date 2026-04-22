class AppConfig {
  static const String androidUrl = 'http://localhost:8080/api';
  static const String phoneUrl = 'http://192.168.1.90:8080/api';
  static const String baseUrl = phoneUrl;

  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register';
  static const String profileUrl = '$baseUrl/users/profile';
  static const String compteursUrl = '$baseUrl/compteurs';
}
