// lib/widgets/download_progress_dialog.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smart_crop_dryer/services/app_update_service.dart';

Future<void> showDownloadProgressDialog(
  BuildContext context,
  String downloadUrl,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DownloadProgressDialog(downloadUrl: downloadUrl),
  );
}

class _DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  const _DownloadProgressDialog({required this.downloadUrl});

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String? _error;
  CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final navigator = Navigator.of(context);
    try {
      final path = await AppUpdateService().downloadApk(
        url: widget.downloadUrl,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );

      if (!mounted) return;
      navigator.pop();

      await OpenFilex.open(path);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Update download failed: $e');
      setState(() {
        _error = e is DioException && e.response?.statusCode == 504
            ? 'GitHub timed out while serving this APK (HTTP 504). Please retry, or ask the app administrator to check the release download link.'
            : 'Download failed: $e';
      });
    }
  }

  void _retryDownload() {
    setState(() {
      _error = null;
      _progress = 0.0;
      _cancelToken = CancelToken();
    });
    _startDownload();
  }

  @override
  void dispose() {
    if (!_cancelToken.isCancelled && _progress < 1.0) {
      _cancelToken.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Downloading Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ] else ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ],
      ),
      actions: [
        if (_error != null)
          TextButton(
            onPressed: _retryDownload,
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            _cancelToken.cancel();
            navigator.pop();
          },
          child: Text(_error != null ? 'Close' : 'Cancel'),
        ),
      ],
    );
  }
}
