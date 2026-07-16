import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/smart_home_control.dart';
import 'package:smart_crop_dryer/services/smart_home_control_service.dart';

class SmartHomeControlViewModel extends ChangeNotifier {
  final SmartHomeControlService controlService;

  SmartHomeControl _control = SmartHomeControl(
    alarm: false,
    fan: false,
    light1: false,
    light2: false,
  );
  SmartHomeControl get control => _control;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<SmartHomeControl>? _subscription;

  SmartHomeControlViewModel({required this.controlService, String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      controlService.updateDeviceId(deviceId);
      _listenToControl();
    }
  }

  void _listenToControl() {
    _subscription?.cancel();
    _subscription = controlService.listenControl().listen((control) {
      _control = control;
      notifyListeners();
    });
  }

  Future<void> _updateAndSet(SmartHomeControl updated) async {
    _isLoading = true;
    notifyListeners();
    try {
      await controlService.updateControlState(updated);
    } catch (e) {
      print('❌ Error updating SmartHome control: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAlarm(bool value) =>
      _updateAndSet(_control.copyWith(alarm: value));
  Future<void> toggleFan(bool value) =>
      _updateAndSet(_control.copyWith(fan: value));
  Future<void> toggleLight1(bool value) =>
      _updateAndSet(_control.copyWith(light1: value));
  Future<void> toggleLight2(bool value) =>
      _updateAndSet(_control.copyWith(light2: value));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
