import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _kHandledVersionKey = 'handled_update_version';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = pkg.version;

      final doc = await _firestore.collection('AppConfig').doc('current').get();
      if (!doc.exists) {
        debugPrint('AppConfig/current not found.');
        return null;
      }

      final data = doc.data()!;
      final latestVersion = data['latestVersion'] as String? ?? currentVersion;
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final releaseNotes = data['releaseNotes'] as String? ?? '';
      final forceUpdate = data['forceUpdate'] as bool? ?? false;

      final prefs = await SharedPreferences.getInstance();
      final handledVersion = prefs.getString(_kHandledVersionKey);
      if (handledVersion != null && handledVersion == latestVersion) {
        debugPrint('Latest version $latestVersion already handled locally.');
        return null;
      }

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
      debugPrint('checkForUpdate failed: $e');
      return null;
    }
  }

  Future<String> downloadApk({
    required String url,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/update.apk';

    final dio = Dio();
    await dio.download(
      url,
      filePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total);
        }
      },
    );

    try {
      final doc = await _firestore.collection('AppConfig').doc('current').get();
      if (doc.exists) {
        final data = doc.data()!;
        final latestVersion = data['latestVersion'] as String?;
        if (latestVersion != null && latestVersion.isNotEmpty) {
          await markVersionHandled(latestVersion);
          debugPrint('Marked $latestVersion as handled after download.');
        }
      }
    } catch (e) {
      debugPrint('Failed to mark version handled after download: $e');
    }

    return filePath;
  }

  Future<void> markVersionHandled(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHandledVersionKey, version);
  }

  Future<void> markLatestVersionHandled() async {
    try {
      final doc = await _firestore.collection('AppConfig').doc('current').get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final latestVersion = data['latestVersion'] as String?;
      if (latestVersion != null && latestVersion.isNotEmpty) {
        await markVersionHandled(latestVersion);
      }
    } catch (e) {
      debugPrint('markLatestVersionHandled failed: $e');
    }
  }

  /// If the installed app version is already the latest (or newer), mark the latest
  /// Firestore version as handled so UI won't keep showing the "update available" note.
  Future<void> markLatestHandledIfInstalled() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version;

      final latestVersion = await fetchLatestVersion();
      if (latestVersion == null || latestVersion.isEmpty) return;

      // If installed >= latest (i.e. latest is not newer), mark handled.
      final latestIsNewer = _isNewerVersion(latestVersion, installedVersion);
      if (!latestIsNewer) {
        await markVersionHandled(latestVersion);
        debugPrint(
          'Installed version $installedVersion >= $latestVersion — marked handled.',
        );
      }
    } catch (e) {
      debugPrint('markLatestHandledIfInstalled failed: $e');
    }
  }

  /// Returns the locally stored handled version (or null).
  Future<String?> getHandledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kHandledVersionKey);
  }

  /// Fetch latestVersion string (or null).
  Future<String?> fetchLatestVersion() async {
    try {
      final doc = await _firestore.collection('AppConfig').doc('current').get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final latest = data['latestVersion'] as String?;
      return (latest != null && latest.isNotEmpty) ? latest : null;
    } catch (e) {
      debugPrint('fetchLatestVersion failed: $e');
      return null;
    }
  }

  Future<void> clearHandledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHandledVersionKey);
  }

  void exitAppForInstallation() {
    SystemNavigator.pop();
  }

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
