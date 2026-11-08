import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:smart_crop_dryer/models/control.dart';

class ControlService {
  DatabaseReference? ref;

  String? _deviceId;

  String? get deviceId => _deviceId;

  static const String _manualAlertWebhookUrl =
      'https://script.google.com/macros/s/AKfycbwReEiqa-lGXftOo5uaJ6vinLj6IiF1eqFl70UQ7iWV5u_ezloZliyy9-Fm5RAHMfed/exec';

  ControlService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }

  Future<void> updateControlState(Control control) async {
    try {
      final previousSnapshot = await ref!.child('autoMode').get();
      final bool previousAutoMode = previousSnapshot.exists
          ? (previousSnapshot.value as bool? ?? true)
          : true;

      var controlData = control.toMap();
      await ref!.update(controlData);

      // Fire the manual-mode warning only on the actual transition
      // from auto -> manual, not on every subsequent manual update
      // (e.g. toggling the fan while already in manual mode).
      if (previousAutoMode == true && control.autoMode == false) {
        _sendManualModeAlert();
      }
    } catch (e) {
      // Error updating control state
      throw Exception('Failed to update control state');
    }
  }

  Future<void> _sendManualModeAlert() async {
    try {
      final phoneSnapshot = await FirebaseDatabase.instance
          .ref('Devices/SmartDryer/$_deviceId/info/phone')
          .get();

      final String? phone = phoneSnapshot.exists
          ? phoneSnapshot.value.toString()
          : null;

      if (phone == null || phone == 'null') return;

      await http.post(
        Uri.parse(_manualAlertWebhookUrl),
        body: jsonEncode({
          'phone': phone,
          'deviceId': _deviceId,
          'time': DateTime.now().toString().split('.').first,
        }),
      );
    } catch (e) {
      // Don't let an SMS failure block the actual control update —
      // this is a best-effort notification, not critical path.
    }
  }

  Stream<Control> listenControl() {
    return ref!.onValue
        .map((event) {
          final dynamic value = event.snapshot.value;

          if (value != null && value is Map<dynamic, dynamic>) {
            return Control.fromMap(Map<String, dynamic>.from(value));
          } else {
            return Control(autoMode: false, fanState: false, lightState: false);
          }
        })
        .handleError((error) {
          return Control(autoMode: false, fanState: false, lightState: false);
        });
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref(
        "Devices/SmartDryer/$deviceId/control",
      );
      _deviceId = deviceId;
    }
  }
}
