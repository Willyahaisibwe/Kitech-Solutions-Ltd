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
    Crop(
      name: 'Cassava',
      iconData: Icons.grain_rounded,
      minTemp: 40,
      maxTemp: 60,
    ),
    Crop(
      name: 'Groundnuts',
      iconData: Icons.grain_sharp,
      minTemp: 38,
      maxTemp: 45,
    ),
    Crop(name: 'Sorghum', iconData: Icons.eco, minTemp: 45, maxTemp: 55),
    Crop(name: 'Cowpeas', iconData: Icons.spa, minTemp: 45, maxTemp: 52),
    Crop(
      name: 'Soybeans',
      iconData: Icons.local_florist,
      minTemp: 40,
      maxTemp: 50,
    ),
    Crop(
      name: 'Sweet Potatoes',
      iconData: MdiIcons.sprout,
      minTemp: 55,
      maxTemp: 65,
    ),
    Crop(name: 'Mango', iconData: MdiIcons.foodApple, minTemp: 50, maxTemp: 60),
    Crop(
      name: 'Onions',
      iconData: Icons.local_dining,
      minTemp: 50,
      maxTemp: 60,
    ),
    Crop(
      name: 'Chili/Pepper',
      iconData: MdiIcons.chiliHot,
      minTemp: 50,
      maxTemp: 60,
    ),
    Crop(name: 'Ginger', iconData: Icons.grass, minTemp: 50, maxTemp: 60),
    Crop(name: 'Garlic', iconData: Icons.lightbulb_outline, minTemp: 50, maxTemp: 60),
    Crop(
      name: 'Mushrooms',
      iconData: MdiIcons.mushroom,
      minTemp: 45,
      maxTemp: 55,
    ),
  ];

  final CropService cropService;

  List<Crop> _selectedCrops = [];

  List<Crop> get availableCrops => _availableCrops;
  List<Crop> get selectedCrops => _selectedCrops;

  // StreamSubscription to manage the real-time listener for selected crops.
  StreamSubscription? _cropsSubscription;

  String? _userId;
  String? get userId => _userId;

  CropViewModel({required this.cropService, String? userId}) {
    if (userId != null && userId.isNotEmpty) {
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
      return;
    }

    // Optimistically add to local list for immediate UI feedback
    _selectedCrops.add(crop);
    notifyListeners();

    try {
      await cropService.addSelectedCrop(userId, crop);
    } catch (e) {
      // Error adding crop to Firestore
      // Rollback optimistic update on failure
      _selectedCrops.removeWhere((c) => c.name == crop.name && c.id == null);
      notifyListeners();
      rethrow; // Re-throw so UI can handle the error
    }
  }

  Future<void> removeCrop(String userId, Crop crop) async {
    if (crop.id == null) {
      return;
    }

    // Optimistically remove from local list for immediate UI feedback
    _selectedCrops.removeWhere((c) => c.id == crop.id);
    notifyListeners();

    try {
      await cropService.deleteSelectedCrop(userId, crop.id!);
    } catch (e) {
      // Error deleting crop from Firestore
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
        }
      }
    } catch (e) {
      // Error during bulk crop deletion
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
