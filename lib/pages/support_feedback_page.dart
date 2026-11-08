import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/view_models/language_view_model.dart';

class SupportFeedbackPage extends StatelessWidget {
  final String supportEmail = "williamahaisibwe@gmail.com";
  final String supportWhatsApp = "+256706727525";

  const SupportFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageViewModel = context.watch<LanguageViewModel>();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          languageViewModel.t('support_feedback'),
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.support_agent_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 16),
                    Text(
                      languageViewModel.t('how_can_we_help'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      languageViewModel.t('here_to_assist'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Contact Support Section
            _buildSectionHeader(languageViewModel.t('contact_us')),
            SizedBox(height: 12),
            _buildContactCard(
              context: context,
              icon: Icons.email_outlined,
              title: languageViewModel.t('email_title'),
              subtitle: languageViewModel.t('email_subtitle'),
              description: languageViewModel.t('email_description'),
              color: Colors.orange,
              onTap: () => _launchEmail(supportEmail, "Support Request"),
            ),
            SizedBox(height: 12),
            _buildContactCard(
              context: context,
              icon: MdiIcons.whatsapp,
              title: languageViewModel.t('whatsapp_title'),
              subtitle: languageViewModel.t('whatsapp_subtitle'),
              description: languageViewModel.t('whatsapp_description'),
              color: Colors.green,
              onTap: () => _launchWhatsApp(
                supportWhatsApp,
                "Hi, I need support with the app.",
              ),
            ),
            SizedBox(height: 12),
            _buildContactCard(
              context: context,
              icon: Icons.phone_outlined,
              title: languageViewModel.t('call_title'),
              subtitle: languageViewModel.t('call_subtitle'),
              description: languageViewModel.t('call_description'),
              color: Colors.blue,
              onTap: () => _makePhoneCall(supportWhatsApp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
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
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // Launch email client
  Future<void> _launchEmail(String email, String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      // You can show a snackbar here to inform the user
    }
  }

  // Launch WhatsApp
  Future<void> _launchWhatsApp(String phoneNumber, String message) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');

    final whatsappUrl = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'WhatsApp is not installed';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }
}
