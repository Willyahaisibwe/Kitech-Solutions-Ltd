import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/user_model.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  AuthService authService = AuthService();

  Future<void> fetchUserData(String userId) async {
    _user = await authService.getUserData(userId);
    notifyListeners();
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String farmLocation,
    required String deviceID,
    required String? phoneNumber,
  }) async {
    return await authService.registerWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      farmLocation: farmLocation,
      deviceID: deviceID,
      phoneNumber: phoneNumber,
    );
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
    bool saveCredentials = true, // Flag to control credential saving
  }) async {
    var user = await authService.signInWithEmailAndPassword(
      email: email,
      password: password,
      rememberMe: rememberMe,
      saveCredentials: saveCredentials,
    );

    if (user != null) {
      _user = user;
      notifyListeners();
    }

    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await authService.sendPasswordResetEmail(email);
  }

  Future<UserModel?> checkRememberMe() async {
    var user = await authService.checkRememberMe();

    if (user != null) {
      _user = user;
      notifyListeners();
    }

    return user;
  }

  Future<bool> getRememberMeStatus() async {
    return await authService.getRememberMeStatus();
  }

  Future<String?> getSavedEmail() async {
    return await authService.getSavedEmail();
  }

  Future<void> signOut({bool clearRememberedCredentials = false}) async {
    await authService.signOut(
      clearRememberedCredentials: clearRememberedCredentials,
    );
    clearUser();
  }

  Future<void> updateUserData(UserModel userModel) async {
    await authService.updateUserData(userModel);
  }

  /// Manually set the current user (used after actions like adding a device)
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
