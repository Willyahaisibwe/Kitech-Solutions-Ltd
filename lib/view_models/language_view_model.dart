import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_crop_dryer/utils/app_translations.dart';

class LanguageViewModel extends ChangeNotifier {
  static const String _prefsKey = 'selected_language';
  String _languageCode = 'en';
  String? _deviceId;

  String get languageCode => _languageCode;

  LanguageViewModel({String? deviceId}) : _deviceId = deviceId {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_prefsKey) ?? 'en';
    notifyListeners();
    await _pushLanguageToFirebase();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
    await _pushLanguageToFirebase();
  }

  /// Called when the dryer's deviceId becomes known/changes (e.g. after login).
  void updateDeviceId(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty && deviceId != _deviceId) {
      _deviceId = deviceId;
      _pushLanguageToFirebase();
    }
  }

  Future<void> _pushLanguageToFirebase() async {
    if (_deviceId == null || _deviceId!.isEmpty) return;
    await FirebaseDatabase.instance
        .ref('Devices/SmartDryer/$_deviceId/info/language')
        .set(_languageCode);
  }

  String t(String key) => AppTranslations.translate(key, _languageCode);
}
