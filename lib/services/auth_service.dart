import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_crop_dryer/models/user_model.dart';
import 'package:smart_crop_dryer/services/cloudinary_config.dart';
import 'package:smart_crop_dryer/services/marketplace_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MarketplaceService _marketplaceService = MarketplaceService();

  // SharedPreferences keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<http.MultipartRequest> createCloudinaryUploadRequest(
    Uint8List imageBytes,
    String userId,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    );

    // No public_id: the preset is unsigned, and unsigned presets can't set
    // overwrite=true, so we let Cloudinary auto-generate a unique id per
    // upload instead of trying to overwrite the same asset each time.
    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.fields['folder'] = 'profile_photos';

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: '${userId}_$timestamp.jpg',
      ),
    );

    return request;
  }

  Future<String?> uploadProfileImageToCloudinary({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be logged in to update your photo.');
    }

    try {
      final request = await createCloudinaryUploadRequest(imageBytes, userId);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw UserDataException(
          'Cloudinary upload failed with status ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final uploadedUrl = decoded['secure_url'] as String?;

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw UserDataException('Cloudinary did not return a valid image URL.');
      }

      // No cache-busting needed: every upload gets a distinct URL now,
      // since we no longer reuse the same public_id.
      final currentUserDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();
      final currentUserData = currentUserDoc.data();
      final currentName = (currentUserData?['name'] as String?) ?? '';

      await _firestore.collection('Users').doc(userId).update({
        'profileImageUrl': uploadedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _marketplaceService.syncSellerProfileAcrossListings(
        sellerId: userId,
        sellerName: currentName,
        sellerPhotoUrl: uploadedUrl,
      );

      return uploadedUrl;
    } catch (e) {
      if (e is UserDataException) {
        rethrow;
      }
      throw UserDataException('Failed to upload profile photo: $e');
    }
  }

  /// Pick an image from gallery, upload it to Cloudinary,
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
        return null;
      }

      final bytes = await pickedFile.readAsBytes();
      return uploadProfileImageToCloudinary(
        imageBytes: bytes,
        userId: user.uid,
      );
    } catch (e) {
      throw UserDataException('Failed to upload profile photo: $e');
    }
  }

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
      debugPrint('Error during auto-login: ${e.toString()}');
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
      throw AuthException(
        'An unexpected error occurred during registration: $e',
      );
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
              await _claimDevice(
                device.deviceId,
                device.type,
                userModel.id,
                phoneNumber: userModel.phoneNumber,
              );

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

          // Devices already claimed — verify ownership of each, but don't
          // block login entirely if one device has been unclaimed/removed
          // externally (e.g. manually reset in the Realtime Database).
          final validDevices = <DeviceEntry>[];

          for (final device in userModel.devices) {
            try {
              await _validateDeviceID(
                device.deviceId,
                device.type,
                userModel.id,
              );
              validDevices.add(device);
            } catch (e) {
              debugPrint(
                '⚠️ Device ${device.deviceId} (${device.type}) is no longer '
                'valid for this user, removing from account: $e',
              );
              // Skip this device, but continue logging in with the rest
            }
          }

          if (validDevices.length != userModel.devices.length) {
            // Sync Firestore so it reflects only the devices that are
            // actually still valid/owned by this user
            await _firestore.collection('Users').doc(userModel.id).update({
              'devices': validDevices.map((d) => d.toMap()).toList(),
            });
          }

          return userModel.copyWith(devices: validDevices);
        } catch (e) {
          await signOut(clearRememberedCredentials: false);
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on DeviceException {
      rethrow;
    } catch (e) {
      throw AuthException('An unexpected error occurred during sign in: $e');
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

    // Backfill: if the legacy deviceID isn't yet in the devices array, add it first
    List<DeviceEntry> currentDevices = List.from(userModel.devices);

    if (userModel.deviceID.isNotEmpty &&
        !currentDevices.any((d) => d.deviceId == userModel.deviceID)) {
      final legacyType = _getDeviceType(userModel.deviceID) ?? 'dryer';
      currentDevices.add(
        DeviceEntry(
          deviceId: userModel.deviceID,
          type: legacyType,
          claimedAt: userModel.createdAt,
          isActive: true,
        ),
      );
    }

    // Prevent adding a duplicate service type the user already owns
    if (currentDevices.any((d) => d.type == deviceType)) {
      throw DeviceException(
        'You already have a ${deviceType[0].toUpperCase()}${deviceType.substring(1)} device linked to your account.',
      );
    }

    // Validate the new device is unclaimed
    await _validateDeviceID(deviceID, deviceType, null);

    // Claim it — carry over the existing account's phone number
    await _claimDevice(
      deviceID,
      deviceType,
      user.uid,
      phoneNumber: userModel.phoneNumber,
    );

    final newDevice = DeviceEntry(
      deviceId: deviceID,
      type: deviceType,
      claimedAt: DateTime.now(),
      isActive: true,
    );

    final updatedDevices = [...currentDevices, newDevice];

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
      final updatedUser = userModel.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('Users')
          .doc(userModel.id)
          .update(updatedUser.toMap());

      await _marketplaceService.syncSellerProfileAcrossListings(
        sellerId: userModel.id,
        sellerName: updatedUser.name,
        sellerPhotoUrl: updatedUser.profileImageUrl,
      );
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
    String userID, {
    String? phoneNumber,
  }) async {
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
        'info/phone': (phoneNumber != null && phoneNumber.isNotEmpty)
            ? phoneNumber
            : 'null',
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
