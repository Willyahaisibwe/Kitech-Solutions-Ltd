import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/widgets/radio_player_card.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Icon(
                Icons.storefront_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Marketplace',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Browse products, tools and supplies'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.pushNamed(context, '/marketplace');
              },
            ),
          ),
          const SizedBox(height: 16),
          const RadioPlayerCard(),
        ],
      ),
    );
  }
}
