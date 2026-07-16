import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/pages/add_device_page.dart';
import 'package:smart_crop_dryer/view_models/device_info_view_model.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool twoFactorEnabled = false;
  bool notificationsEnabled = true;
  AuthViewModel? userViewModel;

  @override
  void initState() {
    super.initState();
    userViewModel = context.read<AuthViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Account Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Section
            // _buildUserProfileSection(),
            // SizedBox(height: 20),

            // Account Information Section
            _buildAccountInfoSection(),
            SizedBox(height: 20),

            // My Devices Section
            _buildDevicesSection(),
            SizedBox(height: 20),

            // App Preferences Section
            //_buildAppPreferencesSection(),
            //SizedBox(height: 20),

            // Security & Privacy Section
            //_buildSecurityPrivacySection(),
            //SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .1),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            userViewModel?.user?.name ?? "User Name",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              "Active User",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/editUserInfo');
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: .8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Account Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: "Name",
            value: userViewModel?.user?.name ?? "Unknown",
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: MdiIcons.mapMarkerOutline,
            label: "Farm Location",
            value: userViewModel?.user?.farmLocation ?? "Unknown",
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: MdiIcons.phone,
            label: "Phone number",
            value: userViewModel?.user?.phoneNumber ?? "Unknown",
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email,
            label: "Email",
            value: userViewModel?.user?.email.toString() ?? "No set",
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: "Member Since",
            value: DateFormat(
              'yyyy-MM-dd',
            ).format(userViewModel!.user!.createdAt),
          ),
          SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.chat_outlined,
            title: "Contact Support",
            subtitle: "Get help from our support team",
            onTap: () {
              Navigator.pushNamed(context, '/supportFeedback');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    final devices = userViewModel?.user?.devices ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.devices_other,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
          title: Text(
            "My Devices",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          subtitle: Text(
            "${devices.length} linked device${devices.length == 1 ? '' : 's'}",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          children: [
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "No devices linked yet.",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              )
            else
              ...devices.map((device) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInfoRow(
                    icon: _iconForDeviceType(device.type),
                    label: _labelForDeviceType(device.type),
                    value: device.deviceId,
                  ),
                );
              }),

            SizedBox(height: 4),
            _buildActionTile(
              icon: Icons.add_circle_outline,
              title: "Add a Device",
              subtitle: "Link a new Smart Dryer, Farm, or Home device",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddDevicePage(),
                  ),
                );
                if (userViewModel?.user?.id != null) {
                  await userViewModel!.fetchUserData(userViewModel!.user!.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForDeviceType(String type) {
    switch (type) {
      case 'dryer':
        return MdiIcons.weatherSunny;
      case 'farm':
        return MdiIcons.sprout;
      case 'home':
        return MdiIcons.homeVariant;
      default:
        return Icons.device_hub;
    }
  }

  String _labelForDeviceType(String type) {
    switch (type) {
      case 'dryer':
        return 'Smart Dryer';
      case 'farm':
        return 'Smart Farm';
      case 'home':
        return 'Smart Home';
      default:
        return 'Device';
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "App Preferences",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.language_outlined,
            title: "Language & Region",
            subtitle: "English (Uganda)",
            onTap: () {
              // Language settings
            },
          ),
          SizedBox(height: 8),
          _buildActionTile(
            icon: MdiIcons.thermometerLines,
            title: "Temperature Unit",
            subtitle: "Celsius (°C)",
            onTap: () {
              // Temperature unit settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPrivacySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.security_outlined,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Security & Privacy",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.verified_user_outlined,
            title: "Two-Factor Authentication",
            subtitle: "Add an extra layer of security",
            value: twoFactorEnabled,
            onChanged: (value) {
              setState(() {
                twoFactorEnabled = value;
              });
            },
          ),
          SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.lock_outline,
            title: "Change Password",
            subtitle: "Update your account password",
            onTap: () {
              // Change password action
            },
          ),
          SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "Learn how we protect your data",
            onTap: () {
              // Privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: Colors.grey.shade600),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithAction({
    required IconData icon,
    required String label,
    required String value,
    required IconData actionIcon,
    required VoidCallback onActionPressed,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onActionPressed,
          icon: Icon(actionIcon),
          iconSize: 20,
          color: Colors.grey.shade600,
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  void _onDeviceIdInfoPressed() {
    var deviceInfoViewModel = context.read<DeviceInfoViewModel>();

    showConfirmationDialog(
      context: context,
      title: 'Device Information',
      message:
          'Mac address : ${deviceInfoViewModel.device?.macAddress}\n'
          'Claimed on: ${DateFormat("yyyy-MM-dd 'at' HH:mm:ss").format(deviceInfoViewModel.device!.claimedAt)}\n'
          'Firmware version : ${deviceInfoViewModel.device?.firmwareVersion}',
      icon: Icons.info_outline,
      confirmText: 'OK',
      onConfirm: () {},
    );
  }
}
