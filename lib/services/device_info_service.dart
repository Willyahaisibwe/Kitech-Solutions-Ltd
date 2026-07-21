import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/device.dart';

class DeviceInfoService {
  DatabaseReference? ref;

  String? _deviceId;
  String? get deviceId => _deviceId;

  DeviceInfoService(String? deviceID) {
    if (deviceID != null && deviceID.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref("Devices/SmartDryer/$deviceID/info");

      _deviceId = deviceID;
    }
  }

  Stream<DeviceInfo?> listenDevice() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return DeviceInfo.fromMap(Map<String, dynamic>.from(value));
          } else {
            return null;
          }
        })
        .handleError((error) {
          return null;
        });
  }

  /// Get current device info (one-time read)
  Future<DeviceInfo?> getDeviceInfo() async {
    try {
      final snapshot = await ref!.get();
      if (snapshot.exists && snapshot.value is Map) {
        return DeviceInfo.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
    } catch (e) {
      // Error getting device info
    }
    return null;
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref("Devices/SmartDryer/$deviceId/info");

      _deviceId = deviceId;
    }
  }
}
