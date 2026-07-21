import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/smart_home_settings.dart';

class SmartHomeSettingsService {
  DatabaseReference? ref;
  String? _deviceId;

  String? get deviceId => _deviceId;

  SmartHomeSettingsService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartHome/$deviceId/settings",
      );
      _deviceId = deviceId;
    }
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartHome/$deviceId/settings",
      );
      _deviceId = deviceId;
    }
  }

  Future<void> updateSettings(SmartHomeSettings settings) async {
    try {
      await ref!.update(settings.toMap());
    } catch (e) {
      // Error updating SmartHome settings
      throw Exception('Failed to update SmartHome settings');
    }
  }

  Stream<SmartHomeSettings> listenSettings() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;
          if (value != null && value is Map<dynamic, dynamic>) {
            return SmartHomeSettings.fromMap(Map<String, dynamic>.from(value));
          }
          return SmartHomeSettings(
            alarmEnabled: false,
            autoLight: false,
            thresholdTemp: 30.0,
          );
        })
        .handleError((error) {
          return SmartHomeSettings(
            alarmEnabled: false,
            autoLight: false,
            thresholdTemp: 30.0,
          );
        });
  }
}
