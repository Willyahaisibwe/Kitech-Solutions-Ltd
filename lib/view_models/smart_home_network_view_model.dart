import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/services/smart_home_device_info_service.dart';

class SmartHomeNetworkViewModel extends ChangeNotifier {
  final SmartHomeDeviceInfoService deviceInfoService;

  double _signalStrength = 0.0;
  bool _isConnected = false;
  DateTime? _lastSeen;
  Timer? _lastSeenTimer;

  double get signalStrength => _signalStrength;
  bool get isConnected => _isConnected;

  StreamSubscription? _networkSubscription;

  SmartHomeNetworkViewModel({
    required this.deviceInfoService,
    String? deviceId,
  }) {
    if (deviceId != null && deviceId.isNotEmpty) {
      deviceInfoService.updateDeviceId(deviceId);
      _startSignalListener();
      _startLastSeenChecker();
    }
  }

  void _startSignalListener() {
    _networkSubscription = deviceInfoService.listenNetworkInfo().listen((
      networkInfo,
    ) {
      if (networkInfo != null) {
        _signalStrength = networkInfo.wifiSignal.toDouble();
        try {
          _lastSeen = DateTime.parse(networkInfo.lastSeen);
        } catch (e) {
          print("Invalid lastSeen format: $e");
          _lastSeen = null;
        }
      }
      notifyListeners();
    });
  }

  void _startLastSeenChecker() {
    _lastSeenTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (_lastSeen != null) {
        final diff = DateTime.now().difference(_lastSeen!);
        final bool newStatus = diff.inSeconds < 35;
        if (_isConnected != newStatus) {
          _isConnected = newStatus;
          notifyListeners();
        }
      } else if (_isConnected != false) {
        _isConnected = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _lastSeenTimer?.cancel();
    super.dispose();
  }
}
