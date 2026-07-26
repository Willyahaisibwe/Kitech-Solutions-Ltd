import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/pages/qr_scanner_page.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';
import 'package:smart_crop_dryer/services/error_handler.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _scanDeviceIdQrCode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      setState(() {
        _deviceIdController.text = scannedCode.trim();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = await _authService.addDeviceToCurrentUser(
        deviceID: _deviceIdController.text.trim(),
      );

      // Refresh the AuthViewModel with the updated user data
      if (mounted) {
        Provider.of<AuthViewModel>(context, listen: false).setUser(updatedUser);

        ErrorHandler.showSuccess(context, 'Device added successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Device')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the Device ID printed on your new device to link it to your account.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  labelText: 'Device ID',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.devices_other),
                  suffixIcon: IconButton(
                    icon: Icon(
                      MdiIcons.qrcodeScan,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Scan QR code',
                    onPressed: _scanDeviceIdQrCode,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a Device ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Device'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
