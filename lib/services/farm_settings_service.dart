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
      print(
        '✅ Farm setting updated: ThresholdMoist = ${settings.thresholdMoist}',
      );
    } catch (e) {
      print('❌ Error updating farm setting: $e');
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
            print(
              '⚠️ Warning: ThresholdMoist is null or not a number. Using default 60.0',
            );
            return FarmSettings(thresholdMoist: 60.0);
          }
        })
        .handleError((error) {
          print('❌ Error listening to ThresholdMoist: $error');
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
