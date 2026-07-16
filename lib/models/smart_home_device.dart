class SmartHomeDeviceInfo {
  final String claimedAt;
  final String firmwareVersion;
  final String macAddress;
  final bool paired;
  final String? userId;

  SmartHomeDeviceInfo({
    required this.claimedAt,
    required this.firmwareVersion,
    required this.macAddress,
    required this.paired,
    this.userId,
  });

  factory SmartHomeDeviceInfo.fromMap(Map<String, dynamic> map) {
    return SmartHomeDeviceInfo(
      claimedAt: map['claimedAt']?.toString() ?? '',
      firmwareVersion: map['firmwareVersion']?.toString() ?? '',
      macAddress: map['macAddress']?.toString() ?? '',
      paired: map['paired'] ?? false,
      userId: map['userId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimedAt': claimedAt,
      'firmwareVersion': firmwareVersion,
      'macAddress': macAddress,
      'paired': paired,
      'userId': userId,
    };
  }
}

class SmartHomeNetworkInfo {
  final String lastSeen;
  final int wifiSignal;

  SmartHomeNetworkInfo({required this.lastSeen, required this.wifiSignal});

  factory SmartHomeNetworkInfo.fromMap(Map<String, dynamic> map) {
    return SmartHomeNetworkInfo(
      lastSeen: map['lastSeen']?.toString() ?? '',
      wifiSignal: (map['wifiSignal'] ?? 0) is int
          ? map['wifiSignal']
          : int.tryParse(map['wifiSignal'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'lastSeen': lastSeen, 'wifiSignal': wifiSignal};
  }

  bool get hasSignal => wifiSignal < 0 && wifiSignal > -100;
}
