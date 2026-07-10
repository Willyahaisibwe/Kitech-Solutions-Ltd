import 'package:firebase_database/firebase_database.dart';

class NetworkService {
  DatabaseReference? ref;

  String? _deviceId;

  String? get deviceId => _deviceId;

  NetworkService(String? deviceID) {
    if (deviceID != null && deviceID.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceID/network",
      );
      _deviceId = deviceID;
    }
  }

  Stream<Map<String, dynamic>> listenSignalStrength() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return Map<String, dynamic>.from(value);
          } else {
            print(
              '⚠️ Warning: Signal strength data is not a Map. Using default value {}',
            );
            return <String, dynamic>{};
          }
        })
        .handleError((error) {
          print('❌ Error listening to signal strength: $error');
          return <String, dynamic>{};
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/network",
      );
      _deviceId = deviceId;
    }
  }
}
