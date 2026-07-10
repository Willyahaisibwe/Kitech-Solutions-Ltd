import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/services/error_handler.dart';
import 'package:smart_crop_dryer/view_models/farm_network_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_settings_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';

class FarmSettingsPage extends StatefulWidget {
  const FarmSettingsPage({super.key});

  @override
  State<FarmSettingsPage> createState() => _FarmSettingsPageState();
}

class _FarmSettingsPageState extends State<FarmSettingsPage> {
  double? _localValue;

  void _showNoInternetDialog(BuildContext context) {
    showConfirmationDialog(
      context: context,
      title: 'The system is offline',
      message:
          'Your system appears to be offline. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      confirmText: 'OK',
      onConfirm: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<FarmSettingsViewModel>();
    final networkVM = context.watch<FarmNetworkViewModel>();
    final isOnline = networkVM.isConnected;

    // Sync local slider value with the live value from Firebase,
    // but only if the user isn't actively dragging it
    _localValue ??= settingsVM.settings.thresholdMoist;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Moisture Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.grass,
                      color: Colors.brown.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Soil Moisture Threshold",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Pump turns on automatically when moisture falls below this level",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "${_localValue!.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Slider(
                    value: _localValue!,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: Colors.green,
                    label: "${_localValue!.toStringAsFixed(0)}%",
                    onChanged: (value) {
                      setState(() {
                        _localValue = value;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "0%",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        Text(
                          "100%",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: settingsVM.isLoading
                    ? null
                    : () async {
                        if (!isOnline) {
                          _showNoInternetDialog(context);
                          return;
                        }

                        await settingsVM.updateThresholdMoist(_localValue!);
                        if (context.mounted) {
                          ErrorHandler.showSuccess(
                            context,
                            "Moisture threshold updated!",
                          );
                          Navigator.pop(context);
                        }
                      },
                child: settingsVM.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
