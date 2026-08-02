import 'package:flutter_test/flutter_test.dart';
import 'package:smart_crop_dryer/services/marketplace_service.dart';

void main() {
  group('MarketplaceService seller profile sync payload', () {
    test('builds payload with the current seller name and photo URL', () {
      final payload = MarketplaceService.buildSellerProfileUpdateData(
        sellerName: 'Ivan',
        sellerPhotoUrl: 'https://example.com/photo.jpg',
      );

      expect(payload, {
        'sellerName': 'Ivan',
        'sellerPhotoUrl': 'https://example.com/photo.jpg',
      });
    });

    test('supports clearing the seller photo', () {
      final payload = MarketplaceService.buildSellerProfileUpdateData(
        sellerName: 'Ivan',
        sellerPhotoUrl: null,
      );

      expect(payload['sellerName'], 'Ivan');
      expect(payload['sellerPhotoUrl'], isNull);
    });
  });
}
