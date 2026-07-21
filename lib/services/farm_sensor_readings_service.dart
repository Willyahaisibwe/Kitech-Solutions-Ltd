import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/farm_sensor_readings.dart';

class FarmSensorReadingsService {
  DatabaseReference? ref;

  String? _deviceId;

  String? get deviceId => _deviceId;

  FarmSensorReadingsService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/sensors",
      );
      _deviceId = deviceId;
    }
  }

  Stream<FarmSensorReadings?> getSensorReadingsStream() {
    return ref!.onValue
        .handleError((error) {
          // Farm sensor stream error
        })
        .map((event) {
          try {
            if (!event.snapshot.exists || event.snapshot.value == null) {
              return null;
            }

            final rawData = event.snapshot.value;

            if (rawData is Map) {
              final json = Map<String, dynamic>.from(rawData);
              final readings = FarmSensorReadings.fromJson(json);
              return readings;
            } else {
              return null;
            }
          } catch (e) {
            // Exception occurred
            return null;
          }
        });
  }

  Future<FarmSensorReadings?> fetchSensorReadingsOnce() async {
    try {
      final event = await ref!.once();

      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final json = Map<String, dynamic>.from(data);

      return FarmSensorReadings.fromJson(json);
    } catch (e) {
      // Error during one-time fetch
      return null;
    }
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartFarm/$deviceId/sensors",
      );
      _deviceId = deviceId;
    }
  }
}
