import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/farm_settings.dart';
import 'package:smart_crop_dryer/services/farm_settings_service.dart';

class FarmSettingsViewModel extends ChangeNotifier {
  final FarmSettingsService settingsService;

  FarmSettings _settings = FarmSettings(thresholdMoist: 60.0);
  FarmSettings get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<FarmSettings>? _subscription;

  FarmSettingsViewModel({required this.settingsService, String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      settingsService.updateDeviceId(deviceId);
      _listenToSettings();
    }
  }

  void _listenToSettings() {
    _subscription?.cancel();
    _subscription = settingsService.listenForThresholdMoistSetting().listen((
      settings,
    ) {
      _settings = settings;
      notifyListeners();
    });
  }

  Future<void> updateThresholdMoist(double value) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = _settings.copyWith(thresholdMoist: value);
      await settingsService.updateThresholdMoistSetting(updated);
    } catch (e) {
      // Error updating threshold moisture
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
