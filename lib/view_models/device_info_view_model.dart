import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/device.dart';
import 'package:smart_crop_dryer/services/device_info_service.dart';

class DeviceInfoViewModel extends ChangeNotifier {
  DeviceInfo? _device;

  final DeviceInfoService deviceInfoService;

  DeviceInfo? get device => _device;

  StreamSubscription? _deviceSubscription;

  bool? isPairingEnabled;

  DeviceInfoViewModel({required this.deviceInfoService, String? deviceId}) {
    if(deviceId != null && deviceId.isNotEmpty) {
      deviceInfoService.updateDeviceId(deviceId);
      _startListeningToDeviceInfo();
    }
  }
  void _startListeningToDeviceInfo() {
    _deviceSubscription = deviceInfoService.listenDevice().listen((event) {
      _device = event;

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }
}
