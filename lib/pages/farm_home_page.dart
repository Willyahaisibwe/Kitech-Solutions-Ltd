import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/pages/service_selector_page.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_control_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_network_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_sensor_readings_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';
import 'package:smart_crop_dryer/services/error_handler.dart';

class FarmHomePage extends StatelessWidget {
  const FarmHomePage({super.key});

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
    final sensorVM = context.watch<FarmSensorReadingsViewModel>();
    final controlVM = context.watch<FarmControlViewModel>();
    final networkVM = context.watch<FarmNetworkViewModel>();
    final authVM = context.watch<AuthViewModel>();

    final readings = sensorVM.readings;
    final isOnline = networkVM.isConnected;
    final hasMultipleServices = (authVM.user?.devices.length ?? 0) > 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Icon(Icons.eco, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text(
              "Smart Farm",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnline ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? "Online" : "Offline",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnline
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // User Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade700, Colors.green.shade500],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final authService = AuthService();
                        final url = await authService
                            .pickAndUploadProfileImage();
                        if (url != null && context.mounted) {
                          final updatedUser = authVM.user!.copyWith();
                          authVM.setUser(updatedUser.copyWith());
                          await authVM.fetchUserData(authVM.user!.id);
                          ErrorHandler.showSuccess(
                            context,
                            'Profile photo updated!',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showError(context, e);
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: authVM.user?.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    authVM.user!.profileImageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.eco,
                                  size: 50,
                                  color: Colors.white,
                                ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green.shade700,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hello,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authVM.user?.name ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Account Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/accountSettings");
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Moisture Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/farmSettings");
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.wb_sunny_outlined,
                    title: 'Weather Info',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/weather");
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Support & Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/supportFeedback");
                    },
                  ),
                  if (hasMultipleServices)
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.swap_horiz,
                      title: 'Switch Service',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServiceSelectorPage(),
                          ),
                        );
                      },
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    textColor: Colors.red.shade600,
                    onTap: () {
                      showConfirmationDialog(
                        context: context,
                        title: 'Logout',
                        message: 'Are you sure you want to logout?',
                        icon: Icons.logout_outlined,
                        confirmText: 'Logout',
                        isDestructive: true,
                        onConfirm: () async {
                          Navigator.pop(context);
                          await authVM.signOut(
                            clearRememberedCredentials: true,
                          );
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/login",
                              (route) => false,
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: sensorVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode banner (read-only, no toggle here)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Smart Farm",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              controlVM.control.autoMode
                                  ? "Automatic Mode Active"
                                  : "Manual Mode",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.eco, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Temperature card (3 probes)
                  _multiProbeCard(
                    icon: Icons.thermostat,
                    iconColor: Colors.orange,
                    label: "Temperature",
                    unit: "°C",
                    labels: const ["T1", "T2", "T3"],
                    v1: readings?.temperature1,
                    v2: readings?.temperature2,
                    v3: readings?.temperature3,
                  ),
                  const SizedBox(height: 16),

                  // Humidity card (3 probes)
                  _multiProbeCard(
                    icon: Icons.water_drop,
                    iconColor: Colors.blue,
                    label: "Humidity",
                    unit: "%",
                    labels: const ["H1", "H2", "H3"],
                    v1: readings?.humidity1,
                    v2: readings?.humidity2,
                    v3: readings?.humidity3,
                  ),
                  const SizedBox(height: 16),

                  // Moisture card (3 probes) + settings shortcut
                  _multiProbeCard(
                    icon: Icons.grass,
                    iconColor: Colors.brown,
                    label: "Soil Moisture",
                    unit: "%",
                    labels: const ["M1", "M2", "M3"],
                    v1: readings?.moisture1,
                    v2: readings?.moisture2,
                    v3: readings?.moisture3,
                    settingsLabel: "Moisture settings",
                    onSettingsTap: () {
                      Navigator.pushNamed(context, '/farmSettings');
                    },
                  ),

                  const SizedBox(height: 20),

                  // Pump control card
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
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.water, color: Colors.blue.shade600),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Water Pump",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                controlVM.control.pumpState
                                    ? "Currently running"
                                    : "Currently off",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: controlVM.control.pumpState,
                          activeColor: Colors.blue,
                          onChanged: controlVM.control.autoMode
                              ? null
                              : (value) {
                                  if (!isOnline) {
                                    _showNoInternetDialog(context);
                                    return;
                                  }
                                  controlVM.togglePump(value);
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Auto / Manual mode control card
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
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            controlVM.control.autoMode
                                ? Icons.auto_mode
                                : Icons.back_hand_outlined,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Automatic Mode",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                controlVM.control.autoMode
                                    ? "Pump runs automatically"
                                    : "Manual control",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: controlVM.control.autoMode,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            if (!isOnline) {
                              _showNoInternetDialog(context);
                              return;
                            }
                            controlVM.toggleAutoMode(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? Colors.grey.shade700).withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: textColor ?? Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _multiProbeCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String unit,
    required List<String> labels,
    required double? v1,
    required double? v2,
    required double? v3,
    String? settingsLabel,
    VoidCallback? onSettingsTap,
  }) {
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _probeValue(labels[0], v1, unit),
              _probeValue(labels[1], v2, unit),
              _probeValue(labels[2], v3, unit),
            ],
          ),
          if (settingsLabel != null && onSettingsTap != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onSettingsTap,
              icon: Icon(Icons.settings, size: 18, color: iconColor),
              label: Text(
                settingsLabel,
                style: TextStyle(color: iconColor, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _probeValue(String label, double? value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value != null ? "${value.toStringAsFixed(1)}$unit" : "--",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
