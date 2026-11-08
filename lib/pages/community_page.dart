import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/widgets/radio_player_card.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/view_models/language_view_model.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  Widget _buildMarketplaceCard(
    BuildContext context,
    LanguageViewModel languageViewModel,
  ) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      color: primary.withValues(alpha: .06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primary.withValues(alpha: .15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, '/marketplace');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageViewModel.t('marketplace'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageViewModel.t('browse_products'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageViewModel = context.watch<LanguageViewModel>();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(languageViewModel.t('community')),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const RadioPlayerCard(),
          const SizedBox(height: 16),
          _buildMarketplaceCard(context, languageViewModel),
        ],
      ),
    );
  }
}
