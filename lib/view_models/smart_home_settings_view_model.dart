import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/smart_home_settings.dart';
import 'package:smart_crop_dryer/services/smart_home_settings_service.dart';

class SmartHomeSettingsViewModel extends ChangeNotifier {
  final SmartHomeSettingsService settingsService;

  SmartHomeSettings _settings = SmartHomeSettings(
    alarmEnabled: false,
    autoLight: false,
    thresholdTemp: 30.0,
    neighbourAlertsEnabled: false,
  );
  SmartHomeSettings get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<SmartHomeSettings>? _subscription;

  SmartHomeSettingsViewModel({
    required this.settingsService,
    String? deviceId,
  }) {
    if (deviceId != null && deviceId.isNotEmpty) {
      settingsService.updateDeviceId(deviceId);
      _listenToSettings();
    }
  }

  void _listenToSettings() {
    _subscription?.cancel();
    _subscription = settingsService.listenSettings().listen((settings) {
      _settings = settings;
      notifyListeners();
    });
  }

  Future<void> _updateAndSet(SmartHomeSettings updated) async {
    _isLoading = true;
    notifyListeners();
    try {
      await settingsService.updateSettings(updated);
    } catch (e) {
      // Error updating SmartHome settings
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAlarmEnabled(bool value) =>
      _updateAndSet(_settings.copyWith(alarmEnabled: value));
  Future<void> toggleAutoLight(bool value) =>
      _updateAndSet(_settings.copyWith(autoLight: value));
  Future<void> setThresholdTemp(double value) =>
      _updateAndSet(_settings.copyWith(thresholdTemp: value));
  Future<void> toggleNeighbourAlerts(bool value) =>
      _updateAndSet(_settings.copyWith(neighbourAlertsEnabled: value));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
