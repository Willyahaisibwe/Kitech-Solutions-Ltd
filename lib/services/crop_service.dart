import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_crop_dryer/models/crop.dart';

class CropService {

  CollectionReference<Map<String, dynamic>> _getUserSelectedCropsCollection(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('selectedCrops');
  }

  Future<void> addSelectedCrop(String userId, Crop crop) async {
    try {
      await _getUserSelectedCropsCollection(userId).add(crop.toMap());
      print('✅ Crop added for user $userId: ${crop.name}');
    } catch (e) {
      print('❌ Error adding crop for user $userId: $e');
      throw Exception('Failed to add crop');
    }
  }

  Future<void> deleteSelectedCrop(String userId, String cropId) async {
    try {
      await _getUserSelectedCropsCollection(userId).doc(cropId).delete();
      print('✅ Crop $cropId deleted for user $userId');
    } catch (e) {
      print('❌ Error deleting crop $cropId for user $userId: $e');
      throw Exception('Failed to delete crop');
    }
  }

  Future<Crop?> getSelectedCropById(String userId, String cropId) async {
    try {
      final docSnapshot = await _getUserSelectedCropsCollection(
        userId
      ).doc(cropId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Crop.fromMap(docSnapshot.data()!, docSnapshot.id);
      } else {
        print('⚠️ Crop $cropId does not exist for user $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error getting crop $cropId for user $userId: $e');
      return null;
    }
  }

  Future<List<Crop>> getSelectedCrops(String userId) async {
    try {
      final querySnapshot = await _getUserSelectedCropsCollection(userId).get();
      final List<Crop> crops = [];
      for (var doc in querySnapshot.docs) {
        try {
          crops.add(Crop.fromMap(doc.data(), doc.id));
        } catch (e) {
          print(
            '⚠️ Warning: Could not parse crop data for document ${doc.id}: $e',
          );
        }
      }
      return crops;
    } catch (e) {
      print('❌ Error getting selected crops for user $userId: $e');
      return [];
    }
  }

  Stream<List<Crop>> listenForSelectedCrops(String userId) {
    return _getUserSelectedCropsCollection(userId)
        .snapshots()
        .map((querySnapshot) {
          final List<Crop> crops = [];
          for (var doc in querySnapshot.docs) {
            try {
              crops.add(Crop.fromMap(doc.data(), doc.id));
            } catch (e) {
              print(
                '⚠️ Warning: Could not parse crop data for document ${doc.id}: $e',
              );
            }
          }
          return crops;
        })
        .handleError((error) {
          print('❌ Error listening to selected crops for user $userId: $error');
          return <Crop>[];
        });
  }
}
