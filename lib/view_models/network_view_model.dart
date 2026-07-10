import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/services/network_service.dart';

class NetworkViewModel extends ChangeNotifier {
  final NetworkService networkService;

  double _signalStrength = 0.0;
  bool _isConnected = false;
  DateTime? _lastSeen;
  Timer? _lastSeenTimer;

  double get signalStrength => _signalStrength;
  bool get isConnected => _isConnected;

  StreamSubscription? _networkSubscription;

  NetworkViewModel({required this.networkService, String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      networkService.updateDeviceId(deviceId);
      _startSignalListener();

      _startLastSeenChecker();
    }
  }

  void _startSignalListener() {
    _networkSubscription = networkService.listenSignalStrength().listen((
      strength,
    ) {
      _signalStrength = strength['wifiSignal']?.toDouble() ?? 0.0;

      final String? lastSeenStr = strength['lastSeen'];
      if (lastSeenStr != null) {
        try {
          _lastSeen = DateTime.parse(lastSeenStr);
        } catch (e) {
          print("Invalid lastSeen format: $e");
          _lastSeen = null;
        }
      }

      notifyListeners();
    });
  }

  void _startLastSeenChecker() {
    _lastSeenTimer = Timer.periodic(Duration(milliseconds: 300), (_) {
      if (_lastSeen != null) {
        final diff = DateTime.now().difference(_lastSeen!);
        final bool newStatus = diff.inSeconds < 35;

        if (_isConnected != newStatus) {
          _isConnected = newStatus;
          notifyListeners();
        }
      } else {
        if (_isConnected != false) {
          _isConnected = false;
          notifyListeners();
        }
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
