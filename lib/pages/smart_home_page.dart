import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/pages/service_selector_page.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_control_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_network_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_sensors_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';
import 'package:smart_crop_dryer/pages/community_page.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';
import 'package:smart_crop_dryer/services/error_handler.dart';
import 'package:smart_crop_dryer/models/voice_command.dart';
import 'package:smart_crop_dryer/widgets/voice_command_button.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SmartHomePage extends StatefulWidget {
  const SmartHomePage({super.key});

  @override
  State<SmartHomePage> createState() => _SmartHomePageState();
}

class _SmartHomePageState extends State<SmartHomePage>
    with SingleTickerProviderStateMixin {
  bool _hasHandledOfflineState = false;
  late AnimationController _fanController;
  late Animation<double> _fanAnimation;

  @override
  void initState() {
    super.initState();
    _fanController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fanAnimation = Tween<double>(begin: 0, end: 1).animate(_fanController);
  }

  @override
  void dispose() {
    _fanController.dispose();
    super.dispose();
  }

  void _updateFanAnimation(bool isRunning) {
    if (isRunning) {
      _fanController.repeat();
    } else {
      _fanController.stop();
    }
  }

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
    final sensorsVM = context.watch<SmartHomeSensorsViewModel>();
    final controlVM = context.watch<SmartHomeControlViewModel>();
    final networkVM = context.watch<SmartHomeNetworkViewModel>();
    final authVM = context.watch<AuthViewModel>();

    final sensors = sensorsVM.sensors;
    final isOnline = networkVM.isConnected;
    final hasMultipleServices = (authVM.user?.devices.length ?? 0) > 1;

    if (!isOnline && !_hasHandledOfflineState) {
      _hasHandledOfflineState = true;
    } else if (isOnline) {
      _hasHandledOfflineState = false;
    }

    // Update fan spin animation when fan state or connection changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFanAnimation(controlVM.control.fan && isOnline);
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Icon(Icons.home_outlined, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text(
              "Smart Home",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          VoiceCommandButton(
            activeColor: Colors.green.shade700,
            commands: _buildSmartHomeVoiceCommands(
              context,
              controlVM,
              isOnline,
              authVM.user?.name ?? 'there',
            ),
          ),
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
                          final updatedUser = authVM.user!.copyWith(
                            profileImageUrl: url,
                          );
                          authVM.setUser(updatedUser);
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
                                    '${authVM.user!.profileImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    key: ValueKey(authVM.user!.profileImageUrl),
                                  ),
                                )
                              : const Icon(
                                  Icons.home_outlined,
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
                    title: 'Home Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/smartHomeSettings");
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
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.groups_outlined,
                    title: 'Community',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunityPage(),
                        ),
                      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header banner
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
                        "Smart Home",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        sensors.motion ? "Motion detected" : "All quiet",
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
                    child: const Icon(Icons.home_outlined, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sensors card (Motion + Temperature)
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sensorTile(
                    icon: Icons.thermostat,
                    iconColor: Colors.orange,
                    label: "Temperature",
                    value: "${sensors.temperature.toStringAsFixed(1)}°C",
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade200),
                  _sensorTile(
                    icon: Icons.sensors,
                    iconColor: sensors.motion
                        ? Colors.red
                        : Colors.grey.shade400,
                    label: "Motion",
                    value: sensors.motion ? "Detected" : "Clear",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Light 1
            _toggleCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: "Light 1",
              subtitle: controlVM.control.light1 ? "On" : "Off",
              value: controlVM.control.light1,
              onChanged: (value) {
                if (!isOnline) {
                  _showNoInternetDialog(context);
                  return;
                }
                controlVM.toggleLight1(value);
              },
            ),
            const SizedBox(height: 16),

            // Light 2
            _toggleCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: "Light 2",
              subtitle: controlVM.control.light2 ? "On" : "Off",
              value: controlVM.control.light2,
              onChanged: (value) {
                if (!isOnline) {
                  _showNoInternetDialog(context);
                  return;
                }
                controlVM.toggleLight2(value);
              },
            ),
            const SizedBox(height: 16),

            // Fan
            _toggleCard(
              iconWidget: RotationTransition(
                turns: _fanAnimation,
                child: Icon(
                  MdiIcons.fan,
                  color: controlVM.control.fan && isOnline
                      ? Colors.blue
                      : Colors.grey.shade600,
                ),
              ),
              iconColor: Colors.blue,
              title: "Fan",
              subtitle: controlVM.control.fan ? "Running" : "Off",
              value: controlVM.control.fan,
              onChanged: (value) {
                if (!isOnline) {
                  _showNoInternetDialog(context);
                  return;
                }
                controlVM.toggleFan(value);
              },
            ),
            const SizedBox(height: 16),

            // Alarm
            _toggleCard(
              icon: Icons.notifications_active_outlined,
              iconColor: Colors.red,
              title: "Alarm",
              subtitle: controlVM.control.alarm ? "Armed" : "Disarmed",
              value: controlVM.control.alarm,
              activeColor: Colors.red,
              onChanged: (value) {
                if (!isOnline) {
                  _showNoInternetDialog(context);
                  return;
                }
                controlVM.toggleAlarm(value);
              },
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

  Widget _sensorTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _toggleCard({
    IconData? icon,
    Widget? iconWidget,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    assert(icon != null || iconWidget != null, 'Provide icon or iconWidget');
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: iconWidget ?? Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor ?? iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  List<VoiceCommand> _buildSmartHomeVoiceCommands(
    BuildContext context,
    SmartHomeControlViewModel controlVM,
    bool isOnline,
    String userName,
  ) {
    return [
      // Light 1
      VoiceCommand(
        triggers: ['turn on light 1', 'turn on the first light', 'light 1 on'],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleLight1(true);
          return null;
        },
        confirmationText: (_) => 'Turning on light 1.',
      ),
      VoiceCommand(
        triggers: [
          'turn off light 1',
          'turn off the first light',
          'light 1 off',
        ],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleLight1(false);
          return null;
        },
        confirmationText: (_) => 'Turning off light 1.',
      ),

      // Light 2
      VoiceCommand(
        triggers: ['turn on light 2', 'turn on the second light', 'light 2 on'],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleLight2(true);
          return null;
        },
        confirmationText: (_) => 'Turning on light 2.',
      ),
      VoiceCommand(
        triggers: [
          'turn off light 2',
          'turn off the second light',
          'light 2 off',
        ],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleLight2(false);
          return null;
        },
        confirmationText: (_) => 'Turning off light 2.',
      ),

      // Lights (both)
      VoiceCommand(
        triggers: ['turn on the lights', 'turn on lights', 'lights on'],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleLight1(true);
          controlVM.toggleLight2(true);
          return null;
        },
        confirmationText: (_) => 'Turning on the lights.',
      ),
      VoiceCommand(
        triggers: ['turn off the lights', 'turn off lights', 'lights off'],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleLight1(false);
          controlVM.toggleLight2(false);
          return null;
        },
        confirmationText: (_) => 'Turning off the lights.',
      ),

      // Fan
      VoiceCommand(
        triggers: ['turn on the fan', 'turn on fan', 'start the fan', 'fan on'],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleFan(true);
          return null;
        },
        confirmationText: (_) => 'Turning on the fan.',
      ),
      VoiceCommand(
        triggers: [
          'turn off the fan',
          'turn off fan',
          'stop the fan',
          'fan off',
        ],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleFan(false);
          return null;
        },
        confirmationText: (_) => 'Turning off the fan.',
      ),

      // Alarm
      VoiceCommand(
        triggers: [
          'arm the alarm',
          'turn on the alarm',
          'activate alarm',
          'alarm on',
        ],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleAlarm(true);
          return null;
        },
        confirmationText: (_) => 'Arming the alarm.',
      ),
      VoiceCommand(
        triggers: [
          'disarm the alarm',
          'turn off the alarm',
          'deactivate alarm',
          'alarm off',
        ],
        onMatch: (_) {
          if (!isOnline) {
            return 'Sorry $userName, the system is currently offline. Please check your connection.';
          }
          controlVM.toggleAlarm(false);
          return null;
        },
        confirmationText: (_) => 'Disarming the alarm.',
      ),

      // Greetings — matching Farm page tone
      VoiceCommand(
        triggers: ['hello', 'hi there', 'hi '],
        onMatch: (_) => null,
        confirmationText: (_) => 'Hello $userName, how can I help you today?',
      ),
      VoiceCommand(
        triggers: ['how are you'],
        onMatch: (_) => null,
        confirmationText: (_) =>
            'I am doing great, $userName! How can I help you today?',
      ),
      VoiceCommand(
        triggers: ['good morning'],
        onMatch: (_) => null,
        confirmationText: (_) =>
            'Good morning $userName! How can I help you today?',
      ),
      VoiceCommand(
        triggers: ['good afternoon'],
        onMatch: (_) => null,
        confirmationText: (_) =>
            'Good afternoon $userName! How can I help you today?',
      ),
      VoiceCommand(
        triggers: ['good evening'],
        onMatch: (_) => null,
        confirmationText: (_) =>
            'Good evening $userName! How can I help you today?',
      ),
      VoiceCommand(
        triggers: ['good night'],
        onMatch: (_) => null,
        confirmationText: (_) => 'Good night $userName, sleep well!',
      ),
    ];
  }
}
