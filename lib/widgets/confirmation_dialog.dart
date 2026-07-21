import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.onConfirm,
    this.iconColor = Colors.blue,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onCancel,
    this.confirmButtonColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor =
        confirmButtonColor ??
        (isDestructive
            ? Colors.red.shade600
            : Theme.of(context).colorScheme.primary);

    final effectiveIconColor = iconColor == Colors.blue && isDestructive
        ? Colors.red.shade600
        : iconColor;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context),
          child: Text(
            cancelText,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveConfirmColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// Helper function to show the dialog
Future<void> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required VoidCallback onConfirm,
  Color iconColor = Colors.blue,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  VoidCallback? onCancel,
  Color? confirmButtonColor,
  bool isDestructive = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return ConfirmationDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmButtonColor: confirmButtonColor,
        isDestructive: isDestructive,
      );
    },
  );
}
