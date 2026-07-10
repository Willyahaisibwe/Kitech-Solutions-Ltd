import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/control.dart';
import 'package:smart_crop_dryer/services/control_service.dart';
import 'dart:async';

class ControlViewModel extends ChangeNotifier {
  
  late Control _control;

  final ControlService controlService;

  StreamSubscription? _controlSubscription;

  Control get control => _control;

  ControlViewModel({required this.controlService, String? deviceId}) {

    _control = Control(autoMode: false, fanState: false, lightState: false);

    if(deviceId != null && deviceId.isNotEmpty) {
      controlService.updateDeviceId(deviceId);
      _startListeningToControlState();
    }
  }

  void _startListeningToControlState() {
    _controlSubscription = controlService.listenControl().listen(
      (newControl) {
        _control = newControl;
        notifyListeners();
      },
      onError: (error) {
        _control = Control(autoMode: false, fanState: false, lightState: false);
        notifyListeners();
      },
      onDone: () {
      },
    );
  }

  void updateControlState({bool? autoMode, bool? fanState, bool? lightState}) {

    _control = _control.copyWith(
      autoMode: autoMode,
      fanState: fanState,
      lightState: lightState
    );
    
    notifyListeners();

    controlService.updateControlState(_control!).then((_) {
      print('✅ ViewModel: Control state updated in Firebase.');
      // No need to call notifyListeners() here again because the stream listener
      // will pick up the change from Firebase and notify listeners.
    }).catchError((error) {
      print('❌ ViewModel Error updating control state in Firebase: $error');
      // Optionally, revert local state or show an error message if Firebase update fails.
    });
  }

  void resetControlState() {
    _control = Control(autoMode: false, fanState: false, lightState: false);
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel the stream subscription when the ViewModel is no longer needed
    // to prevent memory leaks.
    _controlSubscription?.cancel();
    super.dispose();
  }
}