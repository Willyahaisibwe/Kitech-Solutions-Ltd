import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/smart_home_device.dart';
import 'package:smart_crop_dryer/services/smart_home_device_info_service.dart';

class SmartHomeDeviceInfoViewModel extends ChangeNotifier {
  final SmartHomeDeviceInfoService deviceInfoService;

  SmartHomeDeviceInfo? _deviceInfo;
  SmartHomeDeviceInfo? get deviceInfo => _deviceInfo;

  SmartHomeNetworkInfo? _networkInfo;
  SmartHomeNetworkInfo? get networkInfo => _networkInfo;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription<SmartHomeDeviceInfo?>? _infoSubscription;
  StreamSubscription<SmartHomeNetworkInfo?>? _networkSubscription;

  SmartHomeDeviceInfoViewModel({
    required this.deviceInfoService,
    String? deviceId,
  }) {
    if (deviceId != null && deviceId.isNotEmpty) {
      deviceInfoService.updateDeviceId(deviceId);
      _listenToDeviceInfo();
      _listenToNetworkInfo();
    }
  }

  void _listenToDeviceInfo() {
    _infoSubscription?.cancel();
    _infoSubscription = deviceInfoService.listenDeviceInfo().listen((info) {
      _deviceInfo = info;
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToNetworkInfo() {
    _networkSubscription?.cancel();
    _networkSubscription = deviceInfoService.listenNetworkInfo().listen((
      network,
    ) {
      _networkInfo = network;
      notifyListeners();
    });
  }

  bool get isOnline => _networkInfo != null && _networkInfo!.hasSignal;

  @override
  void dispose() {
    _infoSubscription?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }
}
