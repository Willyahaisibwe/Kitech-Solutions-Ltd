import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/control.dart';

class ControlService {
  DatabaseReference? ref;

  String? _deviceId;

  String? get deviceId => _deviceId;

  ControlService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }

  Future<void> updateControlState(Control control) async {
    try {
      var controlData = control.toMap();

      await ref!.update(controlData);
    } catch (e) {
      // Error updating control state
      throw Exception('Failed to update control state');
    }
  }

  Stream<Control> listenControl() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return Control.fromMap(Map<String, dynamic>.from(value));
          } else {
            return Control(autoMode: false, fanState: false, lightState: false);
          }
        })
        .handleError((error) {
          return Control(autoMode: false, fanState: false, lightState: false);
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }
}
