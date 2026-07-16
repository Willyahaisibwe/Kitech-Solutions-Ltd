import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/services/error_handler.dart';
import 'package:smart_crop_dryer/view_models/smart_home_network_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_settings_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';

class SmartHomeSettingsPage extends StatefulWidget {
  const SmartHomeSettingsPage({super.key});

  @override
  State<SmartHomeSettingsPage> createState() => _SmartHomeSettingsPageState();
}

class _SmartHomeSettingsPageState extends State<SmartHomeSettingsPage> {
  double? _localThreshold;

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
    final settingsVM = context.watch<SmartHomeSettingsViewModel>();
    final networkVM = context.watch<SmartHomeNetworkViewModel>();
    final isOnline = networkVM.isConnected;

    // Sync local slider value with live Firebase value, unless user is dragging
    _localThreshold ??= settingsVM.settings.thresholdTemp;

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
          "Home Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Temperature threshold card
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
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.thermostat,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Temperature Threshold",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Fan or alarm can trigger automatically when temperature rises above this level",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "${_localThreshold!.toStringAsFixed(0)}°C",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Slider(
                    value: _localThreshold!,
                    min: 0,
                    max: 60,
                    divisions: 60,
                    activeColor: Colors.green,
                    label: "${_localThreshold!.toStringAsFixed(0)}°C",
                    onChanged: (value) {
                      setState(() {
                        _localThreshold = value;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "0°C",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        Text(
                          "60°C",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Auto Light toggle
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Auto Light",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          settingsVM.settings.autoLight
                              ? "Lights turn on automatically with motion"
                              : "Manual control only",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settingsVM.settings.autoLight,
                    activeColor: Colors.amber.shade700,
                    onChanged: settingsVM.isLoading
                        ? null
                        : (value) {
                            if (!isOnline) {
                              _showNoInternetDialog(context);
                              return;
                            }
                            settingsVM.toggleAutoLight(value);
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Alarm Enabled toggle
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Alarm Enabled",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          settingsVM.settings.alarmEnabled
                              ? "Alarm system is active"
                              : "Alarm system is disabled",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settingsVM.settings.alarmEnabled,
                    activeColor: Colors.red.shade600,
                    onChanged: settingsVM.isLoading
                        ? null
                        : (value) {
                            if (!isOnline) {
                              _showNoInternetDialog(context);
                              return;
                            }
                            settingsVM.toggleAlarmEnabled(value);
                          },
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
                  backgroundColor: Colors.green,
                ),
                onPressed: settingsVM.isLoading
                    ? null
                    : () async {
                        if (!isOnline) {
                          _showNoInternetDialog(context);
                          return;
                        }

                        await settingsVM.setThresholdTemp(_localThreshold!);
                        if (context.mounted) {
                          ErrorHandler.showSuccess(
                            context,
                            "Temperature threshold updated!",
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
