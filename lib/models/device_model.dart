class DeviceModel {
  final String deviceCode;
  final String qrCodeValue;
  final String statut;
  final bool configured;
  final int? proprietaireId;
  final int? compteurId;
  final String? compteurReference;
  final int? captureInterval;
  final String? message;
  final String? lastSeenAt;
  final String? firmwareVersion;
  final String? ipAddress;
  final String? wifiSsid;

  DeviceModel({
    required this.deviceCode,
    required this.qrCodeValue,
    required this.statut,
    required this.configured,
    this.proprietaireId,
    this.compteurId,
    this.compteurReference,
    this.captureInterval,
    this.message,
    this.lastSeenAt,
    this.firmwareVersion,
    this.ipAddress,
    this.wifiSsid,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceCode: json['deviceCode']?.toString() ?? '',
      qrCodeValue: json['qrCodeValue']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'NON_CONFIGURE',
      configured: json['configured'] as bool? ?? false,
      proprietaireId: (json['proprietaireId'] as num?)?.toInt(),
      compteurId: (json['compteurId'] as num?)?.toInt(),
      compteurReference: json['compteurReference']?.toString(),
      captureInterval: (json['captureInterval'] as num?)?.toInt(),
      message: json['message']?.toString(),
      lastSeenAt: json['lastSeenAt']?.toString(),
      firmwareVersion: json['firmwareVersion']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      wifiSsid: json['wifiSsid']?.toString(),
    );
  }

  bool get isActif => statut.toUpperCase() == 'ACTIF';
}
