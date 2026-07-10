import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/user_model.dart';

/// Decides where to send the user after login/auto-login,
/// based on how many devices/services they own.
void navigateAfterAuth(BuildContext context, UserModel user) {
  if (user.devices.isEmpty) {
    // Fallback: legacy account with no devices array populated somehow
    Navigator.pushReplacementNamed(context, '/pageSwitcher');
    return;
  }

  if (user.devices.length == 1) {
    final device = user.devices.first;
    Navigator.pushReplacementNamed(context, _routeForType(device.type));
  } else {
    Navigator.pushReplacementNamed(context, '/serviceSelector');
  }
}

String _routeForType(String type) {
  switch (type) {
    case 'dryer':
      return '/pageSwitcher';
    case 'farm':
      return '/farmHome';
    case 'home':
      return '/homeHome'; // placeholder for future SmartHome
    default:
      return '/pageSwitcher';
  }
}
