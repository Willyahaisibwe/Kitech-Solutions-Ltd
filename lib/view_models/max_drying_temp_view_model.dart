import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/max_drying_temp.dart';
import 'package:smart_crop_dryer/services/settings_service.dart';
import 'dart:async';

class MaxDryingTempViewModel extends ChangeNotifier {
  
  late MaxDryingTemp _maxDryingTemp;

  MaxDryingTemp get maxDryingTemp => _maxDryingTemp;

  final SettingsService settingsService;

  StreamSubscription? _thresholdSubscription;

  MaxDryingTempViewModel({required this.settingsService, String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      settingsService.updateDeviceId(deviceId);
      _maxDryingTemp = MaxDryingTemp(value: 50.0);

      _startListeningToThreshold();
    }
  }

  void _startListeningToThreshold() {
    _thresholdSubscription = settingsService.listenForMaxDryingTempSetting().listen(
      (newMaxDryingTemp) {
        _maxDryingTemp = newMaxDryingTemp;

        notifyListeners();
        print(
          'ViewModel updated with new threshold from DB: ${_maxDryingTemp.value}',
        );
      },
      onError: (error) {
        print('❌ ViewModel Error listening to threshold: $error');

        _maxDryingTemp = MaxDryingTemp(value: 50.0);
        notifyListeners();
      },
      onDone: () {
        print('Stream for threshold is closed.');
      },
    );
  }

  void setMaxDryingTemp(double value) {
    _maxDryingTemp = MaxDryingTemp(value: value);
    notifyListeners();

    settingsService
        .updateMaxDryingTempSetting(_maxDryingTemp)
        .then((_) {
          print('✅ ViewModel: Setting updated in Firebase.');
        })
        .catchError((error) {
          print(
            '❌ ViewModel Error updating max drying temp in Firebase: $error',
          );
        });
  }

  @override
  void dispose() {
    _thresholdSubscription?.cancel();
    super.dispose();
  }
}
