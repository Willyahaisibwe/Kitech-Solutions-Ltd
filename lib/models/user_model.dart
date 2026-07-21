class DeviceEntry {
  final String deviceId;
  final String type; // "dryer" | "farm" | "home"
  final DateTime? claimedAt;
  final bool isActive;

  DeviceEntry({
    required this.deviceId,
    required this.type,
    this.claimedAt,
    required this.isActive,
  });

  factory DeviceEntry.fromMap(Map<String, dynamic> map) {
    return DeviceEntry(
      deviceId: map['deviceId'] ?? '',
      type: map['type'] ?? '',
      claimedAt: map['claimedAt'] != null
          ? (map['claimedAt'] is String
                ? DateTime.tryParse(map['claimedAt'])
                : map['claimedAt'].toDate()) // handles Firestore Timestamp
          : null,
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'type': type,
      'claimedAt': claimedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String farmLocation;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String deviceID; // kept for backward compatibility (Dryer flow)
  final String? profileImageUrl;
  final String? phoneNumber;
  final bool hasClaimedDevice;
  final List<DeviceEntry> devices;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.farmLocation,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.deviceID,
    this.profileImageUrl,
    this.phoneNumber,
    required this.hasClaimedDevice,
    this.devices = const [],
  });

  /// Get the device ID for a specific service type, or null if not owned
  String? deviceIdForType(String type) {
    try {
      return devices.firstWhere((d) => d.type == type).deviceId;
    } catch (_) {
      return null;
    }
  }

  String? get farmDeviceId => deviceIdForType('farm');
  String? get dryerDeviceId => deviceIdForType('dryer');
  String? get homeDeviceId => deviceIdForType('home');

  /// True if the user owns more than one service/device
  bool get hasMultipleServices => devices.length > 1;

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'farmLocation': farmLocation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'deviceID': deviceID,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'hasClaimedDevice': hasClaimedDevice,
      'devices': devices.map((d) => d.toMap()).toList(),
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      try {
        // Firestore Timestamp
        return v.toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      farmLocation: map['farmLocation'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
      deviceID: map['deviceID'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      phoneNumber: map['phoneNumber'],
      hasClaimedDevice: map['hasClaimedDevice'] ?? false,
      devices: map['devices'] != null
          ? (map['devices'] as List)
                .map((d) => DeviceEntry.fromMap(Map<String, dynamic>.from(d)))
                .toList()
          : [],
    );
  }

  // Sentinel used to distinguish "field not passed" from "field explicitly
  // set to null" in copyWith (e.g. clearing profileImageUrl when a user
  // removes their profile photo).
  static const _sentinel = Object();

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? farmLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? deviceID,
    Object? profileImageUrl = _sentinel,
    String? phoneNumber,
    bool? hasClaimedDevice,
    List<DeviceEntry>? devices,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      farmLocation: farmLocation ?? this.farmLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      deviceID: deviceID ?? this.deviceID,
      profileImageUrl: identical(profileImageUrl, _sentinel)
          ? this.profileImageUrl
          : profileImageUrl as String?,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hasClaimedDevice: hasClaimedDevice ?? this.hasClaimedDevice,
      devices: devices ?? this.devices,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, farmLocation: $farmLocation, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, deviceID: $deviceID, profileImageUrl: $profileImageUrl, phoneNumber: $phoneNumber, hasClaimedDevice: $hasClaimedDevice, devices: $devices)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.farmLocation == farmLocation &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.deviceID == deviceID &&
        other.profileImageUrl == profileImageUrl &&
        other.phoneNumber == phoneNumber &&
        other.hasClaimedDevice == hasClaimedDevice;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        farmLocation.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode ^
        deviceID.hashCode ^
        profileImageUrl.hashCode ^
        phoneNumber.hashCode ^
        hasClaimedDevice.hashCode;
  }
}
