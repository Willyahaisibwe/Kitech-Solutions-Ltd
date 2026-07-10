import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/farm_sensor_readings.dart';
import 'package:smart_crop_dryer/services/farm_sensor_readings_service.dart';

class FarmSensorReadingsViewModel extends ChangeNotifier {
  final FarmSensorReadingsService sensorService;

  FarmSensorReadings? _readings;
  FarmSensorReadings? get readings => _readings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription<FarmSensorReadings?>? _subscription;

  FarmSensorReadingsViewModel({required this.sensorService, String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      sensorService.updateDeviceId(deviceId);
      _listenToReadings();
    }
  }

  void _listenToReadings() {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = sensorService.getSensorReadingsStream().listen((readings) {
      _readings = readings;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
