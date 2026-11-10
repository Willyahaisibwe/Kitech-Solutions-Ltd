import 'dart:io';
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

      final doc = await _firestore
          .collection('AppConfig')
          .doc('current')
          .get(const GetOptions(source: Source.server));
      debugPrint('UPDATE CHECK fromCache=${doc.metadata.isFromCache}');

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
      final updateAvailable = _isNewerVersion(latestVersion, currentVersion);
      debugPrint(
        'UPDATE CHECK current=$currentVersion latest=$latestVersion '
        'available=$updateAvailable handled=$handledVersion',
      );
      if (handledVersion == latestVersion && !updateAvailable) {
        debugPrint('Latest version $latestVersion already handled locally.');
        return null;
      }
      if (handledVersion == latestVersion && updateAvailable) {
        await prefs.remove(_kHandledVersionKey);
      }

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

    // Remove any half-downloaded file from an earlier failed attempt
    final oldFile = File(filePath);
    if (await oldFile.exists()) {
      await oldFile.delete();
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
        maxRedirects: 5,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
          'Accept': '*/*',
        },
      ),
    );

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
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
        break; // success
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        final retryable =
            code == 502 ||
            code == 503 ||
            code == 504 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (!retryable || attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return filePath;
  }

  Future<void> markVersionHandled(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHandledVersionKey, version);
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
      final doc = await _firestore
          .collection('AppConfig')
          .doc('current')
          .get(const GetOptions(source: Source.server));
      debugPrint('UPDATE CHECK fromCache=${doc.metadata.isFromCache}');
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
