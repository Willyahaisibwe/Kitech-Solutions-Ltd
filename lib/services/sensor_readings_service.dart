import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/sensor_readings.dart';

class SensorReadingsService {
  DatabaseReference? ref;

  String? _deviceId;

  String? get deviceId => _deviceId;

  SensorReadingsService(String? deviceID) {
    if (deviceID != null && deviceID.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceID/sensors",
      );

      _deviceId = deviceID;
    }
  }

  Stream<SensorReadings?> getSensorReadingsStream() {
    return ref!.onValue
        .handleError((error) {
          // Stream error
        })
        .map((event) {
          try {
            if (!event.snapshot.exists || event.snapshot.value == null) {
              return null;
            }

            final rawData = event.snapshot.value;

            Map<String, dynamic> json;

            if (rawData is Map) {
              json = Map<String, dynamic>.from(rawData);
            } else if (rawData is List) {
              final nonNullItems = (rawData)
                  .where((item) => item != null)
                  .toList();
              if (nonNullItems.isEmpty) {
                return null;
              }
              json = Map<String, dynamic>.from(nonNullItems.first as Map);
            } else {
              return null;
            }

            final sensorReadings = SensorReadings.fromJson(json);
            return sensorReadings;
          } catch (e) {
            // Exception occurred
            return null;
          }
        });
  }

  Future<SensorReadings?> fetchSensorReadingsOnce() async {
    try {
      final event = await ref!.once();

      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final json = Map<String, dynamic>.from(data);

      return SensorReadings.fromJson(json);
    } catch (e) {
      // Error during one-time fetch
      return null;
    }
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/sensors",
      );

      _deviceId = deviceId;
    }
  }
}
