import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/crop.dart';
import 'package:smart_crop_dryer/view_models/crop_view_model.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/view_models/network_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';

class CropSelectionPage extends StatefulWidget {
  const CropSelectionPage({super.key});

  @override
  State<CropSelectionPage> createState() => _CropSelectionPageState();
}

class _CropSelectionPageState extends State<CropSelectionPage> {
  late String userId;
  late Set<String> pendingSelectedCropNames;
  
  @override
  void initState() {
    super.initState();
    userId = context.read<AuthViewModel>().user!.id;
    // Initialize pending selections with current selections using crop names
    final currentSelections = context.read<CropViewModel>().selectedCrops;
    pendingSelectedCropNames = currentSelections.map((crop) => crop.name).toSet();
  }

  void _toggleCropSelection(Crop crop) {
    setState(() {
      if (pendingSelectedCropNames.contains(crop.name)) {
        pendingSelectedCropNames.remove(crop.name);
      } else {
        pendingSelectedCropNames.add(crop.name);
      }
    });
  }

  bool _isPendingSelected(Crop crop) {
    return pendingSelectedCropNames.contains(crop.name);
  }

  void _onSelectCrops() {
    
    final networkViewModel = context.read<NetworkViewModel>();

    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }

    showSaveChangesDialog(context, () async {
      final cropViewModel = context.read<CropViewModel>();
      final availableCrops = cropViewModel.availableCrops;
      final currentSelections = cropViewModel.selectedCrops;
      
      // Find crops to add and remove based on names
      final cropsToAdd = availableCrops.where((crop) => 
        pendingSelectedCropNames.contains(crop.name) && 
        !currentSelections.any((selected) => selected.name == crop.name)
      ).toList();
      
      final cropsToRemove = currentSelections.where((crop) => 
        !pendingSelectedCropNames.contains(crop.name)
      ).toList();
      
      // Apply changes
      for (final crop in cropsToRemove) {
        await cropViewModel.removeCrop(userId, crop);
      }
      
      for (final crop in cropsToAdd) {
        await cropViewModel.addCrop(userId, crop);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Crops updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Select Your Crops",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CropViewModel>(
        builder: (context, cropViewModel, child) {
          final availableCrops = cropViewModel.availableCrops;
          final pendingSelectedCrops = availableCrops.where((crop) => 
            pendingSelectedCropNames.contains(crop.name)
          ).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pending selected crops chips (if any)
                if (pendingSelectedCrops.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected (${pendingSelectedCrops.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: pendingSelectedCrops.map((crop) {
                            return Chip(
                              label: Text(crop.name),
                              deleteIcon: Icon(Icons.close, size: 18),
                              onDeleted: () => _toggleCropSelection(crop),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .1),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: .3),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],

                // Available crops grid
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Crops',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: availableCrops.map((crop) {
                          final isSelected = _isPendingSelected(crop);
                          
                          return GestureDetector(
                            onTap: () => _toggleCropSelection(crop),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: .1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      Icon(
                                        crop.iconData,
                                        size: 40,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.shade600,
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    crop.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${crop.minTemp}°C - ${crop.maxTemp}°C',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Action buttons
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade400,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  MdiIcons.cancel,
                                  size: 20,
                                  color: Colors.red.shade600,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _onSelectCrops,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  MdiIcons.check,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showSaveChangesDialog(BuildContext context, VoidCallback onSave) {
    showConfirmationDialog(
      context: context,
      title: 'Save Changes',
      message: 'Do you want to save your changes?',
      icon: Icons.save_outlined,
      iconColor: Colors.green.shade600,
      confirmText: 'Save',
      confirmButtonColor: Colors.green.shade600,
      onConfirm: onSave,
    );
  }

  void _showNoInternetDialog(BuildContext context) {
    showConfirmationDialog(
      context: context,
      title: 'The system is offline',
      message:
          'Your system appears to be offline. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      confirmText: 'OK',
      onConfirm: () {},
    );
  }
}