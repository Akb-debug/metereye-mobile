// ✅ CRÉÉ — nouveau fichier
// Mappé sur GET /api/devices/my → premier module actif (DeviceModel étendu)

class ModuleIotModel {
  final String deviceCode;
  final String statut;
  final bool configured;
  final String? lastSeenAt;
  final String? firmwareVersion;
  final int? captureInterval;
  final String? wifiSsid;
  final String? ipAddress;
  final int? compteurId;
  final String? compteurReference;
  final String? modeLectureAssocie;
  final String? typeModule;
  final String? bluetoothAddress;

  ModuleIotModel({
    required this.deviceCode,
    required this.statut,
    required this.configured,
    this.lastSeenAt,
    this.firmwareVersion,
    this.captureInterval,
    this.wifiSsid,
    this.ipAddress,
    this.compteurId,
    this.compteurReference,
    this.modeLectureAssocie,
    this.typeModule,
    this.bluetoothAddress,
  });

  factory ModuleIotModel.fromJson(Map<String, dynamic> json) {
    return ModuleIotModel(
      deviceCode: json['deviceCode']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'NON_CONFIGURE',
      configured: json['configured'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt']?.toString(),
      firmwareVersion: json['firmwareVersion']?.toString(),
      captureInterval: (json['captureInterval'] as num?)?.toInt(),
      wifiSsid: json['wifiSsid']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      compteurId: (json['compteurId'] as num?)?.toInt(),
      compteurReference: json['compteurReference']?.toString(),
      modeLectureAssocie: json['modeLectureAssocie']?.toString(),
      typeModule: json['typeModule']?.toString(),
      bluetoothAddress: json['bluetoothAddress']?.toString(),
    );
  }

  /// true si le module est déclaré ACTIF côté backend
  bool get isOnline => statut.toUpperCase() == 'ACTIF';

  /// Libellé humain du type de module
  String get typeLabel {
    final t = (typeModule ?? deviceCode).toUpperCase();
    if (t.contains('ESP32')) return 'ESP32-CAM';
    if (t.contains('PZEM')) return 'Capteur PZEM';
    if (t.contains('SENSOR')) return 'Capteur PZEM';
    return typeModule ?? 'Module IoT';
  }

  /// Dernière lecture formatée lisiblement (ex. "Aujourd'hui 09:47")
  String get lastSeenFormatted {
    if (lastSeenAt == null) return '--';
    final dt = DateTime.tryParse(lastSeenAt!);
    if (dt == null) return lastSeenAt!;
    final now = DateTime.now();
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return "Aujourd'hui $h:$m";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Hier $h:$m';
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} $h:$m';
  }

  /// Libellé de signal — non disponible dans le modèle backend actuel
  String get signalLabel => '--';
}
