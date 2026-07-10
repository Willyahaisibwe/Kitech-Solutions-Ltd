import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';

class ErrorHandler {
  static void showError(BuildContext context, dynamic error) {
    String message;
    Color backgroundColor = Colors.red;
    int duration = 4;

    if (error is DeviceException) {
      message = error.toString();
    } else if (error is AuthException) {
      message = error.toString();
    } else if (error is UserDataException) {
      message = error.toString();
      backgroundColor = Colors.amber;
    } else {
      message = 'An unexpected error occurred';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
