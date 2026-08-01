// lib/pages/listing_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:smart_crop_dryer/models/marketplace_listing.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailPage extends StatelessWidget {
  final MarketplaceListing listing;

  const ListingDetailPage({super.key, required this.listing});

  Future<void> _callSeller() async {
    final uri = Uri(scheme: 'tel', path: listing.sellerPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsAppSeller() async {
    final cleanNumber = listing.sellerPhone.replaceAll(RegExp(r'[\s\-\+]'), '');
    final message =
        'Hi ${listing.sellerName}, I saw your listing for ${listing.itemName} on Kitech Marketplace. Is it still available?';
    final uri = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                listing.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.itemName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "UGX ${priceFormat.format(listing.price)} ${listing.priceUnit}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        listing.location,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (listing.description != null &&
                      listing.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .1),
                          backgroundImage: listing.sellerPhotoUrl != null
                              ? NetworkImage(listing.sellerPhotoUrl!)
                              : null,
                          child: listing.sellerPhotoUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.sellerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "Seller",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callSeller,
                  icon: const Icon(Icons.call_outlined),
                  label: const Text("Call"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _whatsAppSeller,
                  icon: Icon(MdiIcons.whatsapp),
                  label: const Text("WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
