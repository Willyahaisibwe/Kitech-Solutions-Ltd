import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/services/smart_home_device_info_service.dart';

/// One signal-strength sample, timestamped when the app received it —
/// used to draw a rolling live chart, not stored in Firebase.
class SignalSample {
  final DateTime time;
  final double dbm;
  SignalSample(this.time, this.dbm);
}

class SmartHomeNetworkViewModel extends ChangeNotifier {
  final SmartHomeDeviceInfoService deviceInfoService;

  static const Duration _historyWindow = Duration(minutes: 5);

  double _signalStrength = 0.0;
  bool _isConnected = false;
  DateTime? _lastSeen;
  Timer? _lastSeenTimer;
  final List<SignalSample> _history = [];

  double get signalStrength => _signalStrength;
  bool get isConnected => _isConnected;
  List<SignalSample> get history => List.unmodifiable(_history);

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
          // Invalid lastSeen format
          _lastSeen = null;
        }
        _recordSample(_signalStrength);
      }
      notifyListeners();
    });
  }

  void _recordSample(double dbm) {
    final now = DateTime.now();
    _history.add(SignalSample(now, dbm));
    final cutoff = now.subtract(_historyWindow);
    _history.removeWhere((s) => s.time.isBefore(cutoff));
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
