import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/smart_home_device.dart';

class SmartHomeDeviceInfoService {
  DatabaseReference? infoRef;
  DatabaseReference? networkRef;
  String? _deviceId;

  String? get deviceId => _deviceId;

  SmartHomeDeviceInfoService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      _setRefs(deviceId);
      _deviceId = deviceId;
    }
  }

  void _setRefs(String deviceId) {
    infoRef = FirebaseDatabase.instance.ref("Devices/SmartHome/$deviceId/info");
    networkRef = FirebaseDatabase.instance.ref(
      "Devices/SmartHome/$deviceId/network",
    );
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      _setRefs(deviceId);
      _deviceId = deviceId;
    }
  }

  Stream<SmartHomeDeviceInfo?> listenDeviceInfo() {
    return infoRef!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;
          if (value != null && value is Map<dynamic, dynamic>) {
            return SmartHomeDeviceInfo.fromMap(
              Map<String, dynamic>.from(value),
            );
          }
          return null;
        })
        .handleError((error) {
          return null;
        });
  }

  Stream<SmartHomeNetworkInfo?> listenNetworkInfo() {
    return networkRef!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;
          if (value != null && value is Map<dynamic, dynamic>) {
            return SmartHomeNetworkInfo.fromMap(
              Map<String, dynamic>.from(value),
            );
          }
          return null;
        })
        .handleError((error) {
          return null;
        });
  }
}
