import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/smart_home_sensors.dart';
import 'package:smart_crop_dryer/services/smart_home_sensors_service.dart';

class SmartHomeSensorsViewModel extends ChangeNotifier {
  final SmartHomeSensorsService sensorsService;

  SmartHomeSensors _sensors = SmartHomeSensors(motion: false, temperature: 0.0);
  SmartHomeSensors get sensors => _sensors;

  StreamSubscription<SmartHomeSensors>? _subscription;

  SmartHomeSensorsViewModel({required this.sensorsService, String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      sensorsService.updateDeviceId(deviceId);
      _listenToSensors();
    }
  }

  void _listenToSensors() {
    _subscription?.cancel();
    _subscription = sensorsService.listenSensors().listen((sensors) {
      _sensors = sensors;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
