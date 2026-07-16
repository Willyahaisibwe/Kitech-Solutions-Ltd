import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/smart_home_sensors.dart';

class SmartHomeSensorsService {
  DatabaseReference? ref;
  String? _deviceId;

  String? get deviceId => _deviceId;

  SmartHomeSensorsService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartHome/$deviceId/sensors",
      );
      _deviceId = deviceId;
    }
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartHome/$deviceId/sensors",
      );
      _deviceId = deviceId;
    }
  }

  Stream<SmartHomeSensors> listenSensors() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;
          if (value != null && value is Map<dynamic, dynamic>) {
            return SmartHomeSensors.fromMap(Map<String, dynamic>.from(value));
          }
          return SmartHomeSensors(motion: false, temperature: 0.0);
        })
        .handleError((error) {
          print('❌ Error listening to SmartHome sensors: $error');
          return SmartHomeSensors(motion: false, temperature: 0.0);
        });
  }
}
