import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/sensor_readings.dart';
import 'package:smart_crop_dryer/services/sensor_readings_service.dart';

class SensorReadingsViewModel extends ChangeNotifier {

  final SensorReadingsService sensorService;

  SensorReadings? _sensorReadings;

  SensorReadings? get sensorReadings => _sensorReadings;

  StreamSubscription? _sensorReadingsSubscription;


  SensorReadingsViewModel({required this.sensorService, String? deviceId}) {
    if(deviceId != null && deviceId.isNotEmpty) {
      sensorService.updateDeviceId(deviceId);
      _listenToSensorReadings();
    }
  }
  void resetSensorReadings()
  {
    _sensorReadings = SensorReadings(temperature: 0, humidity: 0);
      notifyListeners();
  }

  void _listenToSensorReadings() {
   _sensorReadingsSubscription = sensorService.getSensorReadingsStream().listen((reading) {
      _sensorReadings = reading;
      notifyListeners();
    });
  }

  Future<void> fetchOnce() async {
    final event = await sensorService.fetchSensorReadingsOnce();
    _sensorReadings = event;
    notifyListeners();
  }

  @override
  void dispose()
  {
    _sensorReadingsSubscription?.cancel();
    super.dispose();
  }
}
