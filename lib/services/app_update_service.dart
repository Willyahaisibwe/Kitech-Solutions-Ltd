// lib/services/app_update_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool updateAvailable;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });
}

class AppUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final doc = await _firestore.collection('AppConfig').doc('current').get();

      if (!doc.exists) {
        debugPrint('AppConfig/current not found, skipping update check.');
        return null;
      }

      final data = doc.data()!;
      final latestVersion = data['latestVersion'] as String? ?? currentVersion;
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final releaseNotes = data['releaseNotes'] as String? ?? '';
      final forceUpdate = data['forceUpdate'] as bool? ?? false;

      final updateAvailable = _isNewerVersion(latestVersion, currentVersion);

      return UpdateInfo(
        updateAvailable: updateAvailable,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        forceUpdate: forceUpdate,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Compares two version strings like "1.2.0" vs "1.1.5".
  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      final l = latestParts[i] ?? 0;
      final c = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
