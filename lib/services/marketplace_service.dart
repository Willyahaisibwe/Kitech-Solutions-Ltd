// lib/services/marketplace_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_crop_dryer/models/marketplace_listing.dart';
import 'package:smart_crop_dryer/services/cloudinary_config.dart';

class MarketplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('MarketplaceListings');

  static Map<String, dynamic> buildSellerProfileUpdateData({
    required String sellerName,
    required String? sellerPhotoUrl,
  }) {
    return {'sellerName': sellerName, 'sellerPhotoUrl': sellerPhotoUrl};
  }

  /// Uploads a listing photo to Cloudinary and returns the secure URL.
  Future<String> uploadListingImage(
    Uint8List imageBytes,
    String sellerId,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    );

    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.fields['folder'] = 'marketplace_photos';

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: '${sellerId}_$timestamp.jpg',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Image upload failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final url = decoded['secure_url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return a valid image URL.');
    }

    return url;
  }

  Future<void> createListing(MarketplaceListing listing) async {
    try {
      await _listings.add(listing.toMap());
      debugPrint('✅ Listing created: ${listing.itemName}');
    } catch (e) {
      debugPrint('❌ Error creating listing: $e');
      throw Exception('Failed to create listing');
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _listings.doc(listingId).delete();
    } catch (e) {
      debugPrint('❌ Error deleting listing: $e');
      throw Exception('Failed to delete listing');
    }
  }

  Future<void> syncSellerProfileAcrossListings({
    required String sellerId,
    required String sellerName,
    required String? sellerPhotoUrl,
  }) async {
    try {
      final snapshot = await _listings
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final payload = buildSellerProfileUpdateData(
        sellerName: sellerName,
        sellerPhotoUrl: sellerPhotoUrl,
      );

      final batchSize = 500;
      for (var i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = snapshot.docs.sublist(
          i,
          i + batchSize < snapshot.docs.length
              ? i + batchSize
              : snapshot.docs.length,
        );

        for (final doc in chunk) {
          batch.update(doc.reference, payload);
        }

        await batch.commit();
      }
    } catch (e) {
      debugPrint('❌ Error syncing seller profile across listings: $e');
      throw Exception('Failed to sync seller profile across listings');
    }
  }

  Future<void> markAsSold(String listingId) async {
    try {
      await _listings.doc(listingId).update({'isActive': false});
    } catch (e) {
      debugPrint('❌ Error marking listing sold: $e');
      throw Exception('Failed to update listing');
    }
  }

  /// Live feed of active listings, newest first.
  Stream<List<MarketplaceListing>> listenForActiveListings() {
    return _listings
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final List<MarketplaceListing> listings = [];
          for (final doc in snapshot.docs) {
            try {
              listings.add(MarketplaceListing.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('⚠️ Could not parse listing ${doc.id}: $e');
            }
          }
          return listings;
        });
  }

  /// A seller's own listings (active and sold).
  Stream<List<MarketplaceListing>> listenForMyListings(String sellerId) {
    return _listings
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final List<MarketplaceListing> listings = [];
          for (final doc in snapshot.docs) {
            try {
              listings.add(MarketplaceListing.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('⚠️ Could not parse listing ${doc.id}: $e');
            }
          }
          return listings;
        });
  }
}
