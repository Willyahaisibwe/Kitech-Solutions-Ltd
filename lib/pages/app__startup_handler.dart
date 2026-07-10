import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/user_model.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/widgets/navigation_helper.dart';

class AppStartupHandler extends StatefulWidget {
  const AppStartupHandler({super.key});

  @override
  State<AppStartupHandler> createState() => _AppStartupHandlerState();
}

class _AppStartupHandlerState extends State<AppStartupHandler> {
  bool _isChecking = true;
  AuthViewModel? _authViewModel;

  @override
  void initState() {
    _authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // Check if user wants to be remembered and attempt auto-login
      UserModel? user = await _authViewModel!.checkRememberMe();

      if (user != null) {
        // Auto-login successful, navigate based on how many services the user owns
        navigateAfterAuth(context, user);
      } else {
        // No auto-login, go to login page
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Auto-login failed, go to login page
      print('Auto-login failed: ${e.toString()}');
      Navigator.pushReplacementNamed(context, '/login');
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isChecking) {
      return Container(); // This will be replaced by navigation
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Icon(
              MdiIcons.sprout,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 24),

            // App name
            Text(
              'Smart Crop Dryer',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 40),

            // Loading indicator
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 20),

            // Loading text
            Text(
              'Starting up...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
