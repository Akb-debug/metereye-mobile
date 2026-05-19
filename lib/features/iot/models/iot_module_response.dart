class IotModuleResponse {
  final String deviceCode;
  final String deviceId;
  final String typeModule;
  final String status;
  final bool configured;
  final int? captureInterval;
  final int? compteurId;
  final String? lastReadingAt;
  final String? ipAddress;
  final String? firmwareVersion;
  final String? serialNumber;

  const IotModuleResponse({
    required this.deviceCode,
    required this.deviceId,
    required this.typeModule,
    required this.status,
    required this.configured,
    this.captureInterval,
    this.compteurId,
    this.lastReadingAt,
    this.ipAddress,
    this.firmwareVersion,
    this.serialNumber,
  });

  bool get isActive => status == 'ACTIF' || configured;

  String get typeLabel => switch (typeModule) {
        'ESP32_PZEM004T' => 'Raspberry Pi + PZEM-004T',
        'ESP32_CAM'      => 'ESP32-CAM',
        'SENSOR_GENERIC' => 'Capteur générique',
        'IOT_MODULE'     => 'Module IoT',
        _                => typeModule,
      };

  factory IotModuleResponse.fromJson(Map<String, dynamic> j) => IotModuleResponse(
        deviceCode:      j['deviceCode']?.toString() ?? j['id']?.toString() ?? '',
        deviceId:        j['deviceId']?.toString() ?? '',
        typeModule:      j['typeModule']?.toString() ?? '',
        status:          j['status']?.toString() ?? 'PENDING',
        configured:      j['configured'] as bool? ?? false,
        captureInterval: (j['captureInterval'] as num?)?.toInt(),
        compteurId:      (j['compteurId'] as num?)?.toInt(),
        lastReadingAt:   j['lastReadingAt']?.toString(),
        ipAddress:       j['ipAddress']?.toString(),
        firmwareVersion: j['firmwareVersion']?.toString(),
        serialNumber:    j['serialNumber']?.toString(),
      );
}
