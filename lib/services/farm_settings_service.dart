import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/farm_settings.dart';

class FarmSettingsService {
  DatabaseReference? ref;

  String? _deviceId;
  String? get deviceId => _deviceId;

  FarmSettingsService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/settings",
      );
      _deviceId = deviceId;
    }
  }

  Future<void> updateThresholdMoistSetting(FarmSettings settings) async {
    try {
      await ref!.update({'ThresholdMoist': settings.thresholdMoist});
    } catch (e) {
      // Error updating farm setting
    }
  }

  Stream<FarmSettings> listenForThresholdMoistSetting() {
    return ref!
        .child('ThresholdMoist')
        .onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is num) {
            return FarmSettings(thresholdMoist: value.toDouble());
          } else {
            return FarmSettings(thresholdMoist: 60.0);
          }
        })
        .handleError((error) {
          return FarmSettings(thresholdMoist: 60.0);
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/settings",
      );
      _deviceId = deviceId;
    }
  }
}
