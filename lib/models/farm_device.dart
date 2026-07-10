class FarmDeviceInfo {
  final String claimedAt;
  final String firmwareVersion;
  final String macAddress;
  final bool paired;
  final String? userId;

  FarmDeviceInfo({
    required this.claimedAt,
    required this.firmwareVersion,
    required this.macAddress,
    required this.paired,
    this.userId,
  });

  factory FarmDeviceInfo.fromMap(Map<String, dynamic> map) {
    return FarmDeviceInfo(
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

class FarmNetworkInfo {
  final String lastSeen;
  final int wifiSignal;

  FarmNetworkInfo({required this.lastSeen, required this.wifiSignal});

  factory FarmNetworkInfo.fromMap(Map<String, dynamic> map) {
    return FarmNetworkInfo(
      lastSeen: map['lastSeen']?.toString() ?? '',
      wifiSignal: (map['wifiSignal'] ?? 0) is int
          ? map['wifiSignal']
          : int.tryParse(map['wifiSignal'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'lastSeen': lastSeen, 'wifiSignal': wifiSignal};
  }

  /// Simple helper: is the device likely online?
  /// (You may want to compare lastSeen against current time instead)
  bool get hasSignal => wifiSignal < 0 && wifiSignal > -100;
}
