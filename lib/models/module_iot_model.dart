// ✅ CRÉÉ — nouveau fichier
// Mappé sur GET /api/module-devices/my → ModuleDeviceResponseDTO (Spring Boot backend)

class ModuleIotModel {
  final String deviceCode;
  final String? bluetoothAddress;

  /// Valeur de l'enum TypeModuleDevice : "ESP32_CAM" | "ESP32_PZEM004T" | "SENSOR_GENERIC" | "IOT_MODULE"
  final String? typeModule;

  /// Valeur de l'enum StatutModuleDevice : "ACTIF" | "HORS_LIGNE" | "NON_CONFIGURE" | …
  final String statut;

  final bool configured;
  final DateTime? lastSeenAt;
  final String? firmwareVersion;
  final int? captureInterval;
  final String? wifiSsid;
  final String? ipAddress;
  final int? proprietaireId;
  final int? compteurId;
  final String? compteurReference;
  final String? modeLectureAssocie;

  ModuleIotModel({
    required this.deviceCode,
    this.bluetoothAddress,
    this.typeModule,
    required this.statut,
    required this.configured,
    this.lastSeenAt,
    this.firmwareVersion,
    this.captureInterval,
    this.wifiSsid,
    this.ipAddress,
    this.proprietaireId,
    this.compteurId,
    this.compteurReference,
    this.modeLectureAssocie,
  });

  factory ModuleIotModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['lastSeenAt']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return ModuleIotModel(
      deviceCode: json['deviceCode']?.toString() ?? '',
      bluetoothAddress: json['bluetoothAddress']?.toString(),
      typeModule: json['typeModule']?.toString(),
      statut: json['statut']?.toString() ?? 'NON_CONFIGURE',
      configured: json['configured'] as bool? ?? false,
      lastSeenAt: parsedDate,
      firmwareVersion: json['firmwareVersion']?.toString(),
      captureInterval: (json['captureInterval'] as num?)?.toInt(),
      wifiSsid: json['wifiSsid']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      proprietaireId: (json['proprietaireId'] as num?)?.toInt(),
      compteurId: (json['compteurId'] as num?)?.toInt(),
      compteurReference: json['compteurReference']?.toString(),
      modeLectureAssocie: json['modeLectureAssocie']?.toString(),
    );
  }

  /// Vrai si le statut est "ACTIF" (correspond à StatutModuleDevice.ACTIF côté backend)
  bool get isOnline => statut.toUpperCase() == 'ACTIF';

  /// Libellé humain du type de module
  String get typeLabel {
    switch (typeModule?.toUpperCase()) {
      case 'ESP32_CAM':
        return 'ESP32-CAM';
      case 'ESP32_PZEM004T':
        return 'ESP32-PZEM004T';
      case 'SENSOR_GENERIC':
        return 'Capteur générique';
      case 'IOT_MODULE':
        return 'Module IoT';
      default:
        return typeModule ?? 'Module IoT';
    }
  }

  /// "Aujourd'hui HH:mm" si vu aujourd'hui, sinon "jj/mm HH:mm"
  String get lastSeenFormatted {
    if (lastSeenAt == null) return '--';
    final now = DateTime.now();
    final d = lastSeenAt!;
    final hhmm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return "Aujourd'hui $hhmm";
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hhmm';
  }

  /// Null car le DTO ne contient pas de champ RSSI/signal
  /// La ligne "Signal" sera masquée côté UI si null
  String? get signalLabel => null;
}
