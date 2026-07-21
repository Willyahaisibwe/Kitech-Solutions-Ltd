import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/farm_device.dart';

class FarmDeviceInfoService {
  DatabaseReference? infoRef;
  DatabaseReference? networkRef;

  String? _deviceId;
  String? get deviceId => _deviceId;

  FarmDeviceInfoService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      infoRef = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/info",
      );
      networkRef = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/network",
      );
      _deviceId = deviceId;
    }
  }

  Stream<FarmDeviceInfo?> listenDeviceInfo() {
    return infoRef!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return FarmDeviceInfo.fromMap(Map<String, dynamic>.from(value));
          } else {
            return null;
          }
        })
        .handleError((error) {
          return null;
        });
  }

  Stream<FarmNetworkInfo?> listenNetworkInfo() {
    return networkRef!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return FarmNetworkInfo.fromMap(Map<String, dynamic>.from(value));
          } else {
            return null;
          }
        })
        .handleError((error) {
          return null;
        });
  }

  Future<FarmDeviceInfo?> getDeviceInfo() async {
    try {
      final snapshot = await infoRef!.get();
      if (snapshot.exists && snapshot.value is Map) {
        return FarmDeviceInfo.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
    } catch (e) {
      // Error getting farm device info
    }
    return null;
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      infoRef = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/info",
      );
      networkRef = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/network",
      );
      _deviceId = deviceId;
    }
  }
}
