import '../../../config/app_config.dart';

class BluetoothProvisioningPayload {
  final String ssid;
  final String password;
  // URL complete vers laquelle le module enverra ses releves
  final String backendUrl;
  final int meterId;
  final String deviceId;
  final String token;
  final int captureInterval;

  const BluetoothProvisioningPayload({
    required this.ssid,
    required this.password,
    required this.backendUrl,
    required this.meterId,
    required this.deviceId,
    required this.token,
    required this.captureInterval,
  });

  factory BluetoothProvisioningPayload.build({
    required String ssid,
    required String password,
    required int meterId,
    required String deviceId,
    required String token,
    String moduleType = '',
    int captureInterval = 60,
  }) {
    final isEsp32Cam = moduleType.toUpperCase().contains('CAM');
    return BluetoothProvisioningPayload(
      ssid: ssid,
      password: password,
      backendUrl: isEsp32Cam ? AppConfig.iotImageUrl : AppConfig.iotReadingsUrl,
      meterId: meterId,
      deviceId: deviceId,
      token: token,
      captureInterval: captureInterval,
    );
  }

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'password': password,
        'backendUrl': backendUrl,
        'meterId': meterId,
        'deviceId': deviceId,
        'token': token,
        'captureInterval': captureInterval,
      };
}
