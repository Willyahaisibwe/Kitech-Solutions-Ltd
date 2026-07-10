class DeviceInfo{
  final String userID;
  final String firmwareVersion;
  final bool paired;
  final DateTime claimedAt;
  final String macAddress;

  DeviceInfo({required this.userID, required this.firmwareVersion, required this.paired, required this.claimedAt, required this.macAddress});

 factory DeviceInfo.fromMap(Map<String, dynamic> json) {
    return DeviceInfo(
      userID: json['userId'] ?? '',
      firmwareVersion: json['firmwareVersion'] ?? '',
      paired: json['paired'] ?? false,
      claimedAt: json['claimedAt'] != null ? DateTime.parse(json['claimedAt']) : DateTime.fromMillisecondsSinceEpoch(0),
      macAddress: json['macAddress'] ?? '',
    );
  }
}