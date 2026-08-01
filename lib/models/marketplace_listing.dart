// lib/models/marketplace_listing.dart
class MarketplaceListing {
  final String? id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String sellerPhone;
  final String itemName;
  final String imageUrl;
  final double price;
  final String priceUnit;
  final String location;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  MarketplaceListing({
    this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    required this.sellerPhone,
    required this.itemName,
    required this.imageUrl,
    required this.price,
    required this.priceUnit,
    required this.location,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });

  factory MarketplaceListing.fromMap(Map<String, dynamic> map, String id) {
    return MarketplaceListing(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhotoUrl: map['sellerPhotoUrl'],
      sellerPhone: map['sellerPhone'] ?? '',
      itemName: map['itemName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      priceUnit: map['priceUnit'] ?? '',
      location: map['location'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhotoUrl': sellerPhotoUrl,
      'sellerPhone': sellerPhone,
      'itemName': itemName,
      'imageUrl': imageUrl,
      'price': price,
      'priceUnit': priceUnit,
      'location': location,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
