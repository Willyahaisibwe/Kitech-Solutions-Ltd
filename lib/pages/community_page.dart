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
        children: [const RadioPlayerCard()],
      ),
    );
  }
}
