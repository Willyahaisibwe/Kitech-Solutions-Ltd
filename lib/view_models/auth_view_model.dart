import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/user_model.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _user;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  UserModel? get user => _user;

  AuthService authService = AuthService();

  Future<void> fetchUserData(String userId) async {
    _user = await authService.getUserData(userId);
    notifyListeners();
    _subscribeToUser(userId);
  }

  void _subscribeToUser(String userId) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final userData = Map<String, dynamic>.from(snapshot.data()!);
            userData['id'] = snapshot.id;
            final updatedUser = UserModel.fromMap(userData);

            // Only rebuild dependent providers when something actually
            // changed — otherwise every unrelated Firestore write (or the
            // very first snapshot echo) tears down and recreates every
            // ChangeNotifierProxyProvider that depends on AuthViewModel,
            // which can orphan active streams (like an in-progress
            // ESP-NOW scan) mid-flight.
            if (_user == null ||
                _user!.toMap().toString() != updatedUser.toMap().toString()) {
              _user = updatedUser;
              notifyListeners();
            }
          }
        }, onError: (_) {});
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String farmLocation,
    required String deviceID,
    required String? phoneNumber,
  }) async {
    final user = await authService.registerWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      farmLocation: farmLocation,
      deviceID: deviceID,
      phoneNumber: phoneNumber,
    );

    if (user != null) {
      _user = user;
      notifyListeners();
      _subscribeToUser(user.id);
    }

    return user;
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
      _subscribeToUser(user.id);
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
      _subscribeToUser(user.id);
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
    _subscribeToUser(user.id);
  }

  void clearUser() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = null;
    notifyListeners();
  }
}
