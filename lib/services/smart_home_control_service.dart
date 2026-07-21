import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/smart_home_control.dart';

class SmartHomeControlService {
  DatabaseReference? ref;
  String? _deviceId;

  String? get deviceId => _deviceId;

  SmartHomeControlService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartHome/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }

  Future<void> updateControlState(SmartHomeControl control) async {
    try {
      var controlData = control.toMap();
      await ref!.update(controlData);
    } catch (e) {
      // Error updating SmartHome control state
      throw Exception('Failed to update SmartHome control state');
    }
  }

  Stream<SmartHomeControl> listenControl() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return SmartHomeControl.fromMap(Map<String, dynamic>.from(value));
          } else {
            return SmartHomeControl(
              alarm: false,
              fan: false,
              light1: false,
              light2: false,
            );
          }
        })
        .handleError((error) {
          return SmartHomeControl(
            alarm: false,
            fan: false,
            light1: false,
            light2: false,
          );
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartHome/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }
}
