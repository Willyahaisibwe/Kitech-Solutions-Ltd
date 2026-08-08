class SmartHomeEspNowState {
  final Map<String, bool>
  discovered; // mac_no_colons -> true (found in last scan)
  final Map<String, bool> peerMacs; // mac_no_colons -> true (nodes I notify)
  final Map<String, LinkedByEntry>
  linkedBy; // mac_no_colons -> who linked to me
  final bool scanning;

  SmartHomeEspNowState({
    required this.discovered,
    required this.peerMacs,
    required this.linkedBy,
    required this.scanning,
  });

  factory SmartHomeEspNowState.empty() => SmartHomeEspNowState(
    discovered: {},
    peerMacs: {},
    linkedBy: {},
    scanning: false,
  );

  factory SmartHomeEspNowState.fromMap(Map<String, dynamic> map) {
    return SmartHomeEspNowState(
      discovered: _boolMap(map['Discovered']),
      peerMacs: _boolMap(map['PeerMacs']),
      linkedBy: _linkedByMap(map['LinkedBy']),
      scanning: map['ScanRequest'] is Map
          ? (map['ScanRequest']['active'] ?? false)
          : false,
    );
  }

  static Map<String, bool> _boolMap(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    return Map<String, dynamic>.from(
      raw,
    ).map((key, value) => MapEntry(key, value == true));
  }

  static Map<String, LinkedByEntry> _linkedByMap(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final map = Map<String, dynamic>.from(raw);
    return map.map(
      (key, value) => MapEntry(
        key,
        LinkedByEntry.fromMap(Map<String, dynamic>.from(value)),
      ),
    );
  }
}

class LinkedByEntry {
  final String name;
  final String linkedAt;
  final String deviceId;
  final String? photoUrl;
  final String? ownerUid;

  LinkedByEntry({
    required this.name,
    required this.linkedAt,
    required this.deviceId,
    this.photoUrl,
    this.ownerUid,
  });

  factory LinkedByEntry.fromMap(Map<String, dynamic> map) {
    return LinkedByEntry(
      name: map['name']?.toString() ?? 'Unknown',
      linkedAt: map['linkedAt']?.toString() ?? '',
      deviceId: map['deviceId']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString(),
      ownerUid: map['ownerUid']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'linkedAt': linkedAt,
      'deviceId': deviceId,
      'photoUrl': photoUrl,
      'ownerUid': ownerUid,
    };
  }
}

/// A discovered-but-not-yet-linked neighbour, resolved for display.
class DiscoveredNeighbour {
  final String mac;
  final String deviceId;
  final String ownerName;
  final bool alreadyLinked;
  final String? ownerPhotoUrl;
  final String? ownerUid;

  DiscoveredNeighbour({
    required this.mac,
    required this.deviceId,
    required this.ownerName,
    required this.alreadyLinked,
    this.ownerPhotoUrl,
    this.ownerUid,
  });
}
