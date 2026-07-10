import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/farm_device.dart';
import 'package:smart_crop_dryer/services/farm_device_info_service.dart';

class FarmDeviceInfoViewModel extends ChangeNotifier {
  final FarmDeviceInfoService deviceInfoService;

  FarmDeviceInfo? _deviceInfo;
  FarmDeviceInfo? get deviceInfo => _deviceInfo;

  FarmNetworkInfo? _networkInfo;
  FarmNetworkInfo? get networkInfo => _networkInfo;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription<FarmDeviceInfo?>? _infoSubscription;
  StreamSubscription<FarmNetworkInfo?>? _networkSubscription;

  FarmDeviceInfoViewModel({required this.deviceInfoService, String? deviceId}) {
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

  /// Simple "online" check based on wifi signal presence
  bool get isOnline => _networkInfo != null && _networkInfo!.hasSignal;

  @override
  void dispose() {
    _infoSubscription?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }
}
