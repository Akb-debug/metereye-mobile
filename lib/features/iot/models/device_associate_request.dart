class DeviceAssociateRequest {
  final int compteurId;
  final int captureInterval;

  const DeviceAssociateRequest({
    required this.compteurId,
    this.captureInterval = 60,
  });

  Map<String, dynamic> toJson() => {
        'compteurId': compteurId,
        'captureInterval': captureInterval,
      };
}
