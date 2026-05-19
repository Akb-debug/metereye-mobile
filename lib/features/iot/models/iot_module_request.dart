class IotModuleRequest {
  final String deviceId;
  final String typeModule;
  final String? bluetoothAddress;
  final int captureInterval;
  final int compteurId;
  final String? firmwareVersion;
  final String? serialNumber;

  const IotModuleRequest({
    required this.deviceId,
    required this.typeModule,
    required this.captureInterval,
    required this.compteurId,
    this.bluetoothAddress,
    this.firmwareVersion,
    this.serialNumber,
  });

  factory IotModuleRequest.sensor({
    required String deviceId,
    required int compteurId,
    String? bluetoothAddress,
    String? firmwareVersion,
    String? serialNumber,
  }) =>
      IotModuleRequest(
        deviceId: deviceId,
        typeModule: 'ESP32_PZEM004T',
        captureInterval: 60,
        compteurId: compteurId,
        bluetoothAddress: bluetoothAddress,
        firmwareVersion: firmwareVersion,
        serialNumber: serialNumber,
      );

  factory IotModuleRequest.esp32Cam({
    required String deviceId,
    required int compteurId,
    String? bluetoothAddress,
    String? firmwareVersion,
    String? serialNumber,
  }) =>
      IotModuleRequest(
        deviceId: deviceId,
        typeModule: 'ESP32_CAM',
        captureInterval: 60,
        compteurId: compteurId,
        bluetoothAddress: bluetoothAddress,
        firmwareVersion: firmwareVersion,
        serialNumber: serialNumber,
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'typeModule': typeModule,
        if (bluetoothAddress != null) 'bluetoothAddress': bluetoothAddress,
        'captureInterval': captureInterval,
        'compteurId': compteurId,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
        if (serialNumber != null) 'serialNumber': serialNumber,
      };
}
