class DeviceScanRequest {
  final String qrCode;
  final int userId;

  const DeviceScanRequest({required this.qrCode, required this.userId});

  Map<String, dynamic> toJson() => {'qrCode': qrCode, 'userId': userId};
}
