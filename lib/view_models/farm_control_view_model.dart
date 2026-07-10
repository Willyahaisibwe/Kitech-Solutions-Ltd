import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/farm_control.dart';
import 'package:smart_crop_dryer/services/farm_control_service.dart';

class FarmControlViewModel extends ChangeNotifier {
  final FarmControlService controlService;

  FarmControl _control = FarmControl(pumpState: false, autoMode: false);
  FarmControl get control => _control;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<FarmControl>? _subscription;

  FarmControlViewModel({required this.controlService, String? deviceId}) {
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

  Future<void> togglePump(bool value) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = _control.copyWith(pumpState: value);
      await controlService.updateControlState(updated);
    } catch (e) {
      print('❌ Error toggling pump: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAutoMode(bool value) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = _control.copyWith(autoMode: value);
      await controlService.updateControlState(updated);
    } catch (e) {
      print('❌ Error toggling auto mode: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
