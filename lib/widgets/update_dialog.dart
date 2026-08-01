// lib/widgets/update_dialog.dart
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/services/app_update_service.dart';
import 'package:smart_crop_dryer/widgets/download_progress_dialog.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A new version (${info.latestVersion}) is available.'),
          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              info.releaseNotes,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            showDownloadProgressDialog(context, info.downloadUrl);
          },
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}
