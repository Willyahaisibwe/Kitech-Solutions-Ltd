import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/crop.dart';
import 'package:smart_crop_dryer/view_models/crop_view_model.dart';
import 'package:smart_crop_dryer/view_models/max_drying_temp_view_model.dart';
import 'package:smart_crop_dryer/view_models/network_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';

enum CropStatus { good, warning, bad }

class TemperatureSettingsPage extends StatefulWidget {
  const TemperatureSettingsPage({super.key});

  @override
  State<TemperatureSettingsPage> createState() =>
      _TemperatureSettingsPageState();
}

class _TemperatureSettingsPageState extends State<TemperatureSettingsPage>
    with TickerProviderStateMixin {
  late List<Crop> selectedCrops = [];
  late double _temperature;
  late MaxDryingTempViewModel maxDryingTempViewModel;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    selectedCrops = context.read<CropViewModel>().selectedCrops;
    maxDryingTempViewModel = context.read<MaxDryingTempViewModel>();
    _temperature = maxDryingTempViewModel.maxDryingTemp.value;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onSave() {
    final networkViewModel = context.read<NetworkViewModel>();

    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }

    showSaveChangesDialog(context, () {
      maxDryingTempViewModel.setMaxDryingTemp(_temperature);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Temperature saved: ${_temperature.round()}°C'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context);
      });
    });
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  CropStatus _getStatusForCrop(Crop crop) {
    if (_temperature >= crop.minTemp && _temperature <= crop.maxTemp) {
      return CropStatus.good;
    } else if ((_temperature - crop.maxTemp).abs() <= 2 ||
        (_temperature - crop.minTemp).abs() <= 2) {
      return CropStatus.warning;
    } else {
      return CropStatus.bad;
    }
  }

  Color _getTemperatureColor() {
    if (_temperature < 30) {
      return Colors.blue.shade600;
    } else if (_temperature < 50) {
      return Colors.green.shade600;
    } else if (_temperature < 65) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  String _getTemperatureDescription() {
    if (_temperature < 30) {
      return "Low temperature - suitable for delicate crops";
    } else if (_temperature < 50) {
      return "Moderate temperature - good for most crops";
    } else if (_temperature < 65) {
      return "High temperature - use with caution";
    } else {
      return "Very high temperature - may damage crops";
    }
  }

  Widget _buildCropCompatibility() {
    if (selectedCrops.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              MdiIcons.informationOutline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12),
            Text(
              "No crops selected",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Select crops to see temperature compatibility",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: selectedCrops.map((crop) {
        final status = _getStatusForCrop(crop);
        final iconStatus = switch (status) {
          CropStatus.good => Icons.check_circle,
          CropStatus.warning => Icons.warning,
          CropStatus.bad => Icons.error,
        };
        final color = switch (status) {
          CropStatus.good => Colors.green.shade600,
          CropStatus.warning => Colors.orange.shade600,
          CropStatus.bad => Colors.red.shade600,
        };
        final bgColor = switch (status) {
          CropStatus.good => Colors.green.shade50,
          CropStatus.warning => Colors.orange.shade50,
          CropStatus.bad => Colors.red.shade50,
        };
        final message = switch (status) {
          CropStatus.good => 'Ideal Temperature',
          CropStatus.warning => 'Acceptable Range',
          CropStatus.bad => 'Too High/Low',
        };

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: .3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  crop.iconData,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Optimal: ${crop.minTemp.toInt()}–${crop.maxTemp.toInt()}°C",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(iconStatus, color: color, size: 20),
                  SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Temperature Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Temperature Control Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTemperatureColor().withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.thermostat,
                            color: _getTemperatureColor(),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Maximum Drying Temperature',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Temperature Display
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getTemperatureColor().withValues(alpha: .1),
                            _getTemperatureColor().withValues(alpha: .05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_temperature.round()}°C',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _getTemperatureColor(),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getTemperatureDescription(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Temperature Slider
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _getTemperatureColor(),
                            inactiveTrackColor: _getTemperatureColor()
                                .withValues(alpha: .2),
                            thumbColor: _getTemperatureColor(),
                            overlayColor: _getTemperatureColor().withValues(
                              alpha: .2,
                            ),
                            trackHeight: 6,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: _temperature,
                            min: 20,
                            max: 80,
                            divisions: 60,
                            onChanged: (newValue) {
                              setState(() {
                                _temperature = newValue;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '20°C',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '80°C',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Crop Compatibility Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            MdiIcons.checkboxMultipleMarked,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Crop Compatibility",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Compatibility Legend
                    if (selectedCrops.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem(
                              icon: Icons.check_circle,
                              color: Colors.green.shade600,
                              label: "Ideal",
                            ),
                            _buildLegendItem(
                              icon: Icons.warning,
                              color: Colors.orange.shade600,
                              label: "Acceptable",
                            ),
                            _buildLegendItem(
                              icon: Icons.error,
                              color: Colors.red.shade600,
                              label: "Risky",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // All crops displayed without scrolling
                    _buildCropCompatibility(),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Action Buttons
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        onTap: _onCancel,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14),
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
                        onTap: _onSave,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getTemperatureColor(),
                                _getTemperatureColor().withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getTemperatureColor().withValues(
                                  alpha: .3,
                                ),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.contentSave,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Save Settings',
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
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
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
