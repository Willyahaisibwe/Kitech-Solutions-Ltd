import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/max_drying_temp.dart';

class SettingsService {
  DatabaseReference? ref;

  String? _deviceId;
  String? get deviceId => _deviceId;

  SettingsService(String? deviceID) {
    if (deviceID != null && deviceID.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceID/settings",
      );
      _deviceId = deviceID;
    }
  }

  Future<void> updateMaxDryingTempSetting(MaxDryingTemp maxDryingTemp) async {
    try {
      await ref!.update({'thresholdTemp': maxDryingTemp.value});
    } catch (e) {
      // Error updating setting
    }
  }

  Stream<MaxDryingTemp> listenForMaxDryingTempSetting() {
    return ref!
        .child('thresholdTemp')
        .onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is num) {
            return MaxDryingTemp(value: value.toDouble());
          } else {
            return MaxDryingTemp(value: 30.0);
          }
        })
        .handleError((error) {
          return MaxDryingTemp(value: 30.0);
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/settings",
      );
      _deviceId = deviceId;
    }
  }
}
