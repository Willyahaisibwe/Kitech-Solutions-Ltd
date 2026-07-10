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
      print('✅ Setting updated: ${maxDryingTemp.value}');
    } catch (e) {
      print('❌ Error updating setting: $e');
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
            print(
              '⚠️ Warning: thresholdTemp is null or not a number. Using default 30.0',
            );
            return MaxDryingTemp(value: 30.0);
          }
        })
        .handleError((error) {
          print('❌ Error listening to thresholdTemp: $error');
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
