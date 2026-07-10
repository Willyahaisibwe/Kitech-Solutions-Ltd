import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_crop_dryer/models/user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pick an image from gallery, upload it to Firebase Storage,
  /// and update the user's profileImageUrl in Firestore.
  Future<String?> pickAndUploadProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be logged in to update your photo.');
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile == null) {
        // User cancelled picking
        return null;
      }

      final file = File(pickedFile.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(file);

      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('Users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw UserDataException('Failed to upload profile photo: $e');
    }
  }

  // SharedPreferences keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Determine the service type ("dryer" | "farm" | "home") from the device ID prefix
  String? _getDeviceType(String deviceID) {
    final id = deviceID.toUpperCase();
    if (id.startsWith('DRY')) return 'dryer';
    if (id.startsWith('SMF')) return 'farm';
    if (id.startsWith('SMH')) return 'home';
    return null;
  }

  /// Get the correct RTDB node name for a given service type
  String _getNodeForType(String type) {
    switch (type) {
      case 'dryer':
        return 'SmartDryer';
      case 'farm':
        return 'SmartFarm';
      case 'home':
        return 'SmartHome';
      default:
        throw DeviceException('Unknown device type');
    }
  }

  Future<UserModel?> checkRememberMe() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (rememberMe) {
        String? email = prefs.getString(_savedEmailKey);
        String? password = prefs.getString(_savedPasswordKey);

        if (email != null && password != null) {
          return await signInWithEmailAndPassword(
            email: email,
            password: password,
            saveCredentials: false,
          );
        }
      }
    } catch (e) {
      print('Error during auto-login: ${e.toString()}');
      await clearRememberMe();
    }
    return null;
  }

  Future<void> saveRememberMe({
    required bool rememberMe,
    String? email,
    String? password,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (rememberMe && email != null && password != null) {
      await prefs.setString(_savedEmailKey, email);
      await prefs.setString(_savedPasswordKey, password);
    } else {
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
    }
  }

  Future<void> clearRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
  }

  Future<bool> getRememberMeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<String?> getSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (rememberMe) {
      return prefs.getString(_savedEmailKey);
    }
    return null;
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String farmLocation,
    required String deviceID,
    required String? phoneNumber,
  }) async {
    try {
      final deviceType = _getDeviceType(deviceID);
      if (deviceType == null) {
        throw DeviceException(
          'Device ID "$deviceID" has an unrecognized prefix. Must start with DRY, SMF, or SMH.',
        );
      }

      await _validateDeviceID(deviceID, deviceType, null);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification();

        // Keep old deviceID field populated ONLY for dryer (backward compatibility)
        final legacyDeviceID = deviceType == 'dryer' ? deviceID : '';

        UserModel userModel = UserModel(
          id: user.uid,
          name: name,
          email: email,
          farmLocation: farmLocation,
          createdAt: DateTime.now(),
          deviceID: legacyDeviceID,
          isActive: false,
          phoneNumber: phoneNumber,
          hasClaimedDevice: false,
          devices: [
            DeviceEntry(deviceId: deviceID, type: deviceType, isActive: false),
          ],
        );

        await _firestore
            .collection('Users')
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on DeviceException {
      rethrow;
    } catch (e) {
      throw AuthException('An unexpected error occurred during registration');
    }
    return null;
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
    bool saveCredentials = true,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        throw AuthException('User not found');
      }

      if (!user.emailVerified) {
        await _auth.signOut();
        throw AuthException(
          'Please verify your email address before signing in.',
        );
      }

      if (saveCredentials) {
        await saveRememberMe(
          rememberMe: rememberMe,
          email: rememberMe ? email : null,
          password: rememberMe ? password : null,
        );
      }

      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        var userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);

        try {
          if (!userModel.hasClaimedDevice && userModel.devices.isNotEmpty) {
            // Claim all devices that haven't been marked active yet
            final updatedDevices = <DeviceEntry>[];

            for (final device in userModel.devices) {
              await _validateDeviceID(device.deviceId, device.type, null);
              await _claimDevice(device.deviceId, device.type, userModel.id);

              updatedDevices.add(
                DeviceEntry(
                  deviceId: device.deviceId,
                  type: device.type,
                  claimedAt: DateTime.now(),
                  isActive: true,
                ),
              );
            }

            var updatedUserModel = userModel.copyWith(
              hasClaimedDevice: true,
              isActive: true,
              devices: updatedDevices,
            );

            await _firestore
                .collection('Users')
                .doc(updatedUserModel.id)
                .update({
                  'hasClaimedDevice': true,
                  'isActive': true,
                  'devices': updatedDevices.map((d) => d.toMap()).toList(),
                });

            return updatedUserModel;
          }

          // Devices already claimed — verify ownership of each
          for (final device in userModel.devices) {
            await _validateDeviceID(device.deviceId, device.type, userModel.id);
          }

          return userModel;
        } catch (e) {
          await signOut(clearRememberedCredentials: false);
          throw e;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on DeviceException {
      rethrow;
    } catch (e) {
      throw AuthException('An unexpected error occurred during sign in');
    }
    return null;
  }

  /// Add a new device (Farm, Home, etc.) to an already-registered, logged-in user
  Future<UserModel> addDeviceToCurrentUser({required String deviceID}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be logged in to add a device.');
    }

    final deviceType = _getDeviceType(deviceID);
    if (deviceType == null) {
      throw DeviceException(
        'Device ID "$deviceID" has an unrecognized prefix. Must start with DRY, SMF, or SMH.',
      );
    }

    // Fetch current user data
    DocumentSnapshot doc = await _firestore
        .collection('Users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      throw UserDataException('User data not found.');
    }

    var userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);

    // Prevent adding a duplicate service type the user already owns
    if (userModel.devices.any((d) => d.type == deviceType)) {
      throw DeviceException(
        'You already have a ${deviceType[0].toUpperCase()}${deviceType.substring(1)} device linked to your account.',
      );
    }

    // Validate the device is unclaimed
    await _validateDeviceID(deviceID, deviceType, null);

    // Claim it
    await _claimDevice(deviceID, deviceType, user.uid);

    // Update the user's devices array
    final newDevice = DeviceEntry(
      deviceId: deviceID,
      type: deviceType,
      claimedAt: DateTime.now(),
      isActive: true,
    );

    final updatedDevices = [...userModel.devices, newDevice];

    await _firestore.collection('Users').doc(user.uid).update({
      'devices': updatedDevices.map((d) => d.toMap()).toList(),
    });

    return userModel.copyWith(devices: updatedDevices);
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      throw UserDataException('Error fetching user data');
    }
    return null;
  }

  Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection('Users')
          .doc(userModel.id)
          .update(userModel.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw UserDataException('Error updating user data');
    }
  }

  Future<void> signOut({bool clearRememberedCredentials = false}) async {
    try {
      await _auth.signOut();
      if (clearRememberedCredentials) {
        await clearRememberMe();
      }
    } catch (e) {
      throw AuthException('Error signing out');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Unable to send password reset email');
    }
  }

  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await clearRememberMe();
        await _firestore.collection('Users').doc(user.uid).delete();
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'This operation is sensitive and requires recent authentication. Please log in again.',
        );
      } else {
        throw _handleAuthException(e);
      }
    } catch (e) {
      throw AuthException('Error deleting account');
    }
  }

  /// Validates a device ID exists under the correct service node
  Future<void> _validateDeviceID(
    String deviceID,
    String deviceType,
    String? userID,
  ) async {
    try {
      final node = _getNodeForType(deviceType);

      final DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref('Devices')
          .child(node)
          .child(deviceID)
          .child('info');

      final DataSnapshot snapshot = await deviceRef.get();

      if (!snapshot.exists) {
        throw DeviceException(
          'Device ID "$deviceID" does not exist. Please check your device ID and try again.',
        );
      }

      final dynamic deviceData = snapshot.value;

      if (deviceData is Map) {
        final Map<String, dynamic> deviceInfo = Map<String, dynamic>.from(
          deviceData,
        );

        final dynamic rawUserId = deviceInfo['userId'];

        final String? assignedUserID =
            (rawUserId == null || rawUserId == 'null')
            ? null
            : rawUserId.toString();

        final bool? isAlreadyClaimed = deviceInfo['paired'];

        if (assignedUserID != null &&
            assignedUserID.isNotEmpty &&
            userID == null) {
          throw DeviceException(
            'Device ID "$deviceID" is already registered to another user. Please contact support if this is your device.',
          );
        }

        if (isAlreadyClaimed == true && userID == null) {
          throw DeviceException(
            'Device ID "$deviceID" has already been claimed. Please contact support if this is your device.',
          );
        }

        if (userID != null && assignedUserID != userID) {
          throw DeviceException(
            'Cannot login: Device ID "$deviceID" is not assigned to this user. Please contact support if this is your device.',
          );
        }
      } else {
        throw DeviceException(
          'Device ID "$deviceID" has invalid data format. Please contact support.',
        );
      }
    } catch (e) {
      if (e is DeviceException) {
        rethrow;
      } else {
        throw DeviceException(
          'Unable to verify device ID. Please check your internet connection and try again.',
        );
      }
    }
  }

  /// Claim and pair a device by assigning it to the user, under the correct service node
  Future<void> _claimDevice(
    String deviceID,
    String deviceType,
    String userID,
  ) async {
    try {
      final node = _getNodeForType(deviceType);

      final DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref('Devices')
          .child(node)
          .child(deviceID);

      final Map<String, dynamic> deviceUpdates = {
        'info/userId': userID,
        'info/paired': true,
        'info/claimedAt': DateTime.now().toIso8601String(),
      };

      // Service-specific default control values
      if (deviceType == 'dryer') {
        deviceUpdates['control/autoMode'] = true;
        deviceUpdates['control/fanState'] = false;
        deviceUpdates['settings/thresholdTemp'] = 22.0;
      } else if (deviceType == 'farm') {
        deviceUpdates['control/autoMode'] = true;
        deviceUpdates['control/PumpState'] = false;
        deviceUpdates['settings/ThresholdMoist'] = 60.0;
      }

      await deviceRef.update(deviceUpdates);
    } catch (e) {
      throw DeviceException(
        'Failed to assign device to user. Registration completed but device setup failed.',
      );
    }
  }

  AuthException _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with that email.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Try again later.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = e.message ?? 'Authentication error occurred';
        break;
    }
    return AuthException(message);
  }
}

// CUSTOM EXCEPTION CLASSES

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class DeviceException implements Exception {
  final String message;
  DeviceException(this.message);

  @override
  String toString() => message;
}

class UserDataException implements Exception {
  final String message;
  UserDataException(this.message);

  @override
  String toString() => message;
}
