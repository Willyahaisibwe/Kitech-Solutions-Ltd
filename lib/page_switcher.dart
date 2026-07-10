import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/pages/home_page.dart';
import 'package:smart_crop_dryer/view_models/network_view_model.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';
import 'package:smart_crop_dryer/pages/service_selector_page.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';
import 'package:smart_crop_dryer/services/error_handler.dart';

class PageSwitcher extends StatefulWidget {
  const PageSwitcher({super.key});

  @override
  State<PageSwitcher> createState() => _PageSwitcherState();
}

class _PageSwitcherState extends State<PageSwitcher> {
  @override
  Widget build(BuildContext context) {
    AuthViewModel authViewModel = context.watch<AuthViewModel>();
    NetworkViewModel networkViewModel = context.watch<NetworkViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                MdiIcons.sprout,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Smart Crop Dryer",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Online status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: networkViewModel.isConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: networkViewModel.isConnected
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: networkViewModel.isConnected
                              ? Colors.green.shade500
                              : Colors.red.shade500,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        networkViewModel.isConnected ? "Online" : "Offline",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: networkViewModel.isConnected
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // WiFi strength
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, color: Colors.grey.shade600, size: 18),
                    SizedBox(width: 4),
                    Text(
                      networkViewModel.isConnected
                          ? '${networkViewModel.signalStrength.toStringAsFixed(0)} dBm'
                          : "No signal",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.grey.shade700),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // User Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: .8),
                  ],
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
                          await authViewModel.fetchUserData(
                            authViewModel.user!.id,
                          );
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
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: authViewModel.user?.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    authViewModel.user!.profileImageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  MdiIcons.sprout,
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
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Hello,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .9),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    authViewModel.user?.name ?? "User",
                    style: TextStyle(
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
                padding: EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Account Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/accountSettings");
                    },
                  ),
                  _buildDrawerItem(
                    icon: MdiIcons.flower,
                    title: 'Select Crops',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/cropSelection");
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.thermostat_outlined,
                    title: 'Temperature Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/temperatureSettings");
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Weather Info',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/weather");
                    },
                  ),
                  //SizedBox(height: 8),
                  // _buildDrawerItem(
                  //   icon: MdiIcons.chartLine,
                  //   title: 'Historical Data',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     Navigator.pushNamed(context, "/historicalData");
                  //   },
                  // ),
                  _buildDrawerItem(
                    icon: MdiIcons.messageAlertOutline,
                    title: 'Support & Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/supportFeedback");
                    },
                  ),
                  if ((authViewModel.user?.devices.length ?? 0) > 1)
                    _buildDrawerItem(
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
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    textColor: Colors.red.shade600,
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: HomePage(),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.transparent,
      hoverColor: (textColor ?? Theme.of(context).colorScheme.primary)
          .withValues(alpha: .05),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showConfirmationDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      icon: Icons.logout_outlined,
      confirmText: 'Logout',
      isDestructive: true,
      onConfirm: () async {
        Navigator.pop(context); // Close the dialog
        await _handleLogout(context);
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logging out...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Clear user data from view model first
      context.read<AuthViewModel>().clearUser();

      // Sign out from Firebase and clear remember me
      await context.read<AuthViewModel>().signOut(
        clearRememberedCredentials: true,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to login page
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/login",
        (route) => false, // Remove all previous routes
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Optional: Add a quick logout option in the drawer for better UX
  Widget _buildQuickLogoutItem() {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.logout_outlined,
          size: 20,
          color: Colors.red.shade600,
        ),
      ),
      title: Text(
        'Quick Logout',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red.shade600,
        ),
      ),
      subtitle: Text(
        'Logout and clear remember me',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      onTap: () async {
        Navigator.pop(context); // Close drawer
        await _handleLogout(context);
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
