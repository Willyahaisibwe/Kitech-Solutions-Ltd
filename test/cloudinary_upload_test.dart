import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_crop_dryer/services/auth_service.dart';

void main() {
  test(
    'creates a Cloudinary upload request with the expected fields',
    () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      final request = await AuthService.createCloudinaryUploadRequest(
        imageBytes,
        'user-123',
      );

      expect(request.fields['upload_preset'], 'kitech_profile_photos');
      expect(request.fields['folder'], 'profile_photos');
      expect(request.fields.containsKey('public_id'), isFalse);
      expect(request.files.length, 1);
      expect(request.files.first.field, 'file');
      expect(request.files.first.filename, startsWith('user-123_'));
      expect(request.files.first.filename, endsWith('.jpg'));
    },
  );
}
