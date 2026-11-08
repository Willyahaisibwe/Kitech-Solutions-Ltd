import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/pages/add_device_page.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/view_models/language_view_model.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  AuthViewModel? userViewModel;

  @override
  void initState() {
    super.initState();
    userViewModel = context.read<AuthViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    final languageViewModel = context.watch<LanguageViewModel>();
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
          languageViewModel.t('account_settings'),
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
            // Account Information Section
            _buildAccountInfoSection(languageViewModel),
            SizedBox(height: 20),

            // My Devices Section
            _buildDevicesSection(languageViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(LanguageViewModel languageViewModel) {
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
                languageViewModel.t('account_information'),
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
            label: languageViewModel.t('name'),
            value: userViewModel?.user?.name ?? languageViewModel.t('unknown'),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: MdiIcons.mapMarkerOutline,
            label: languageViewModel.t('farm_location'),
            value:
                userViewModel?.user?.farmLocation ??
                languageViewModel.t('unknown'),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: MdiIcons.phone,
            label: languageViewModel.t('phone_number'),
            value:
                userViewModel?.user?.phoneNumber ??
                languageViewModel.t('unknown'),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email,
            label: languageViewModel.t('email'),
            value:
                userViewModel?.user?.email.toString() ??
                languageViewModel.t('not_set'),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: languageViewModel.t('member_since'),
            value: DateFormat(
              'yyyy-MM-dd',
            ).format(userViewModel!.user!.createdAt),
          ),
          SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.chat_outlined,
            title: languageViewModel.t('contact_support'),
            subtitle: languageViewModel.t('get_help_support'),
            onTap: () {
              Navigator.pushNamed(context, '/supportFeedback');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection(LanguageViewModel languageViewModel) {
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
            languageViewModel.t('my_devices'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          subtitle: Text(
            "${devices.length} ${devices.length == 1 ? languageViewModel.t('linked_device') : languageViewModel.t('linked_devices')}",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          children: [
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  languageViewModel.t('no_devices_linked'),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              )
            else
              ...devices.map((device) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInfoRow(
                    icon: _iconForDeviceType(device.type),
                    label: _labelForDeviceType(device.type, languageViewModel),
                    value: device.deviceId,
                  ),
                );
              }),

            SizedBox(height: 4),
            _buildActionTile(
              icon: Icons.add_circle_outline,
              title: languageViewModel.t('add_a_device'),
              subtitle: languageViewModel.t('add_device_subtitle'),
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

  String _labelForDeviceType(String type, LanguageViewModel languageViewModel) {
    switch (type) {
      case 'dryer':
        return languageViewModel.t('smart_dryer');
      case 'farm':
        return languageViewModel.t('smart_farm');
      case 'home':
        return languageViewModel.t('smart_home');
      default:
        return languageViewModel.t('device');
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
}
