import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/smart_home_sensors.dart';

class SmartHomeSensorsService {
  DatabaseReference? ref;
  String? _deviceId;

  String? get deviceId => _deviceId;

  SmartHomeSensorsService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref("Devices/SmartHome/$deviceId");
      _deviceId = deviceId;
    }
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref("Devices/SmartHome/$deviceId");
      _deviceId = deviceId;
    }
  }

  Stream<SmartHomeSensors> listenSensors() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;
          if (value != null && value is Map<dynamic, dynamic>) {
            final root = Map<String, dynamic>.from(value);
            final sensorsMap = root['sensors'] is Map
                ? Map<String, dynamic>.from(root['sensors'] as Map)
                : <String, dynamic>{};
            final networkMap = root['network'] is Map
                ? Map<String, dynamic>.from(root['network'] as Map)
                : <String, dynamic>{};
            return SmartHomeSensors.fromMap({...sensorsMap, ...networkMap});
          }
          return SmartHomeSensors(motion: false, temperature: 0.0);
        })
        .handleError((error) {
          // Error listening to SmartHome sensors
          return SmartHomeSensors(motion: false, temperature: 0.0);
        });
  }
}
