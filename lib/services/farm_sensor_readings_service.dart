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
          print('❌ Farm sensor stream error: $error');
        })
        .map((event) {
          try {
            if (!event.snapshot.exists || event.snapshot.value == null) {
              print('⚠️ No data found at farm sensors node');
              return null;
            }

            final rawData = event.snapshot.value;

            if (rawData is Map) {
              final json = Map<String, dynamic>.from(rawData);
              print('🔄 Attempting to create FarmSensorReadings from JSON...');
              final readings = FarmSensorReadings.fromJson(json);
              print('✅ Successfully created FarmSensorReadings');
              return readings;
            } else {
              print('❌ Unexpected data type: ${rawData.runtimeType}');
              return null;
            }
          } catch (e) {
            print('❌ Exception: $e');
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
      print('❌ Error during one-time fetch: $e');
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
