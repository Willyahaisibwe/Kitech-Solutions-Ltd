import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/farm_control.dart';

class FarmControlService {
  DatabaseReference? ref;

  String? _deviceId;

  String? get deviceId => _deviceId;

  FarmControlService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }

  Future<void> updateControlState(FarmControl control) async {
    try {
      var controlData = control.toMap();

      await ref!.update(controlData);
    } catch (e) {
      // Error updating farm control state
      throw Exception('Failed to update farm control state');
    }
  }

  Stream<FarmControl> listenControl() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return FarmControl.fromMap(Map<String, dynamic>.from(value));
          } else {
            return FarmControl(pumpState: false, autoMode: false);
          }
        })
        .handleError((error) {
          return FarmControl(pumpState: false, autoMode: false);
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }
}
