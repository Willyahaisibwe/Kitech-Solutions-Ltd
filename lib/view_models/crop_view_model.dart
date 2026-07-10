import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:smart_crop_dryer/models/crop.dart';
import 'package:smart_crop_dryer/services/crop_service.dart';
import 'dart:async';

class CropViewModel extends ChangeNotifier {

  final List<Crop> _availableCrops = [
    Crop(name: 'Maize', iconData: MdiIcons.corn, minTemp: 48, maxTemp: 55),
    Crop(name: 'Wheat', iconData: Icons.grain, minTemp: 50, maxTemp: 60),
    Crop(name: 'Rice', iconData: Icons.rice_bowl, minTemp: 47, maxTemp: 53),
    Crop(name: 'Beans', iconData: Icons.food_bank, minTemp: 45, maxTemp: 52),
    Crop(name: 'Coffee', iconData: Icons.local_cafe, minTemp: 46, maxTemp: 50),
    Crop(name: 'Millet', iconData: Icons.grass, minTemp: 42, maxTemp: 48),
    Crop(name: 'Cassava', iconData: Icons.grain_rounded, minTemp: 40, maxTemp: 60),
    Crop(name: 'Groundnuts', iconData: Icons.grain_sharp, minTemp: 38, maxTemp: 45),
  ];

  final CropService cropService;

  List<Crop> _selectedCrops = [];

  List<Crop> get availableCrops => _availableCrops;
  List<Crop> get selectedCrops => _selectedCrops;

  // StreamSubscription to manage the real-time listener for selected crops.
  StreamSubscription? _cropsSubscription;

  String ? _userId;
  String ? get userId => _userId;

  CropViewModel({required this.cropService, String? userId})
  {
    if (userId != null && userId.isNotEmpty)
    {
      _userId = userId;
      startListening(userId);
    }
  }

  void startListening(String userId) {
    // Cancel any existing subscription to prevent multiple listeners.
    _cropsSubscription?.cancel();

    _cropsSubscription = cropService
        .listenForSelectedCrops(userId)
        .listen(
          (newCrops) {
            _selectedCrops = [];
            for (var crop in newCrops) {
                _selectedCrops.add(crop);
            }

            notifyListeners();
          },
          onError: (error) {
            print('❌ ViewModel Error listening to selected crops: $error');
            _selectedCrops = [];
            notifyListeners();
          },
        );
  }

  // Helper method to check if a crop is already selected
  bool _isCropSelected(Crop crop) {
    return _selectedCrops.any((existingCrop) => existingCrop.name == crop.name);
  }


  Future<void> addCrop(String userId, Crop crop) async {
    
    if (_isCropSelected(crop)) {
      print('⚠️ Crop ${crop.name} is already selected');
      return;
    }

    // Optimistically add to local list for immediate UI feedback
    _selectedCrops.add(crop);
    notifyListeners();

    try {
      await cropService.addSelectedCrop(userId, crop);
      print('✅ Crop added to Firestore: ${crop.name}');
    } catch (e) {
      print('❌ Error adding crop to Firestore: $e');
      // Rollback optimistic update on failure
      _selectedCrops.removeWhere((c) => c.name == crop.name && c.id == null);
      notifyListeners();
      rethrow; // Re-throw so UI can handle the error
    }
  }

  Future<void> removeCrop(String userId, Crop crop) async {
    if (crop.id == null) {
      print(
        '⚠️ Cannot remove crop: Crop has no ID (not yet saved to Firestore or ID missing).',
      );
      return;
    }

    // Optimistically remove from local list for immediate UI feedback
    _selectedCrops.removeWhere((c) => c.id == crop.id);
    notifyListeners();

    try {
      await cropService.deleteSelectedCrop(userId, crop.id!);
      print('✅ Crop deleted from Firestore: ${crop.name}');
    } catch (e) {
      print('❌ Error deleting crop from Firestore: $e');
      // Rollback optimistic update on failure
      _selectedCrops.add(crop);
      notifyListeners();
      rethrow; // Re-throw so UI can handle the error
    }
  }


  Future<void> clearCrops(String userId) async {
    // Create a copy to avoid modifying the list while iterating
    final List<Crop> cropsToDelete = List.from(_selectedCrops);

    // Optimistically clear locally for immediate feedback
    _selectedCrops.clear();
    notifyListeners();

    try {
      for (var crop in cropsToDelete) {
        if (crop.id != null) {
          await cropService.deleteSelectedCrop(userId, crop.id!);
          print('✅ Deleted ${crop.name} from Firestore.');
        } else {
          print('⚠️ Skipping crop without ID during clear: ${crop.name}');
        }
      }
    } catch (e) {
      print('❌ Error during bulk crop deletion: $e');
      // Rollback on failure
      _selectedCrops = cropsToDelete;
      notifyListeners();
      rethrow;
    }
  }

  // Batch update method for better performance when making multiple changes
  // Future<void> updateSelectedCrops(
  //   String userId,
  //   List<Crop> newSelectedCrops,
  // ) async {
  //   // Find crops to add
  //   final cropsToAdd = newSelectedCrops
  //       .where((crop) => !_isCropSelected(crop))
  //       .toList();

  //   // Find crops to remove
  //   final cropsToRemove = _selectedCrops
  //       .where(
  //         (crop) =>
  //             !newSelectedCrops.any((newCrop) => newCrop.name == crop.name),
  //       )
  //       .toList();

  //   try {
  //     // Remove crops first
  //     for (var crop in cropsToRemove) {
  //       await removeCrop(userId, crop);
  //     }

  //     // Add new crops
  //     for (var crop in cropsToAdd) {
  //       await addCrop(userId, crop);
  //     }
  //   } catch (e) {
  //     print('❌ Error during batch crop update: $e');
  //     rethrow;
  //   }
  // }

  // // Get count of selected crops
  // int get selectedCropsCount => _selectedCrops.length;

  // // Check if any crops are selected
  // bool get hasSelectedCrops => _selectedCrops.isNotEmpty;

  // // Get temperature range for all selected crops
  // Map<String, double> get temperatureRange {
  //   if (_selectedCrops.isEmpty) {
  //     return {'min': 0, 'max': 0};
  //   }

  //   double minTemp = _selectedCrops
  //       .map((c) => c.minTemp)
  //       .reduce((a, b) => a < b ? a : b);
  //   double maxTemp = _selectedCrops
  //       .map((c) => c.maxTemp)
  //       .reduce((a, b) => a > b ? a : b);

  //   return {'min': minTemp, 'max': maxTemp};
  // }

  @override
  void dispose() {
    // Cancel the stream subscription when the ViewModel is no longer needed
    _cropsSubscription?.cancel();
    super.dispose();
  }
}
