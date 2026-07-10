import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/user_model.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';

class ServiceSelectorPage extends StatelessWidget {
  const ServiceSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final devices = user?.devices ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Choose a Service",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${user?.name ?? 'there'}!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Select which service you'd like to open",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return _ServiceCard(device: device);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final DeviceEntry device;

  const _ServiceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(device.type);

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, config.route);
      },
      child: Container(
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(config.icon, color: config.color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.deviceId,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  _ServiceConfig _configFor(String type) {
    switch (type) {
      case 'dryer':
        return _ServiceConfig(
          title: 'Smart Dryer',
          icon: MdiIcons.sprout,
          color: Colors.green.shade700,
          route: '/pageSwitcher',
        );
      case 'farm':
        return _ServiceConfig(
          title: 'Smart Farm',
          icon: Icons.eco,
          color: Colors.green.shade700,
          route: '/farmHome',
        );
      case 'home':
        return _ServiceConfig(
          title: 'Smart Home',
          icon: MdiIcons.homeVariant,
          color: Colors.blue.shade700,
          route: '/homeHome',
        );
      default:
        return _ServiceConfig(
          title: 'Device',
          icon: Icons.device_hub,
          color: Colors.grey.shade700,
          route: '/pageSwitcher',
        );
    }
  }
}

class _ServiceConfig {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _ServiceConfig({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
