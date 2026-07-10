import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/crop.dart';
import 'package:smart_crop_dryer/view_models/control_view_model.dart';
import 'package:smart_crop_dryer/view_models/crop_view_model.dart';
import 'package:smart_crop_dryer/view_models/max_drying_temp_view_model.dart';
import 'package:smart_crop_dryer/view_models/network_view_model.dart';
import 'package:smart_crop_dryer/view_models/sensor_readings_view_model.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/widgets/confirmation_dialog.dart';
import 'package:smart_crop_dryer/widgets/gradient_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasHandledOfflineState = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateAnimation(bool isRunning) {
    if (isRunning) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  Color _getTemperatureColor(double temperature, double threshold) {
    if (temperature > threshold * 0.9) {
      return Colors.red.shade600;
    } else if (temperature > threshold * 0.7) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  Color _getHumidityColor(double humidity) {
    if (humidity > 70) {
      return Colors.blue.shade700;
    } else if (humidity > 40) {
      return Colors.blue.shade500;
    } else {
      return Colors.orange.shade600;
    }
  }

  IconData _getIconStatusForTemperature(
    double temperature,
    double maxThreshold,
  ) {
    double difference = temperature - maxThreshold;

    if (difference > 8) {
      return Icons.dangerous; // Way too hot
    } else if (difference > 4) {
      return Icons.error; // Too hot
    } else if (difference > 1) {
      return Icons.warning; // Slightly above
    } else {
      return Icons.check_circle; // Within acceptable range
    }
  }

  String _getTextStatusForTemperature(double temperature, double maxThreshold) {
    double difference = temperature - maxThreshold;

    if (difference > 8) {
      return "Well above limit (+${difference.toStringAsFixed(1)}°C)";
    } else if (difference > 4) {
      return "Above limit (+${difference.toStringAsFixed(1)}°C)";
    } else if (difference > 1) {
      return "Slightly above limit (+${difference.toStringAsFixed(1)}°C)";
    } else if (difference > -1) {
      return "At limit";
    } else {
      return "Below limit (${difference.abs().toStringAsFixed(1)}°C under)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkViewModel = context.watch<NetworkViewModel>();
    final selectedCrops = context.watch<CropViewModel>().selectedCrops;
    final sensorReadingsViewModel = context.watch<SensorReadingsViewModel>();
    final maxDryingTempViewModel = context.watch<MaxDryingTempViewModel>();
    final controlViewModel = context.watch<ControlViewModel>();

    final sensorData = sensorReadingsViewModel.sensorReadings;

    if (sensorData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final temperature = sensorData.temperature;
    final humidity = sensorData.humidity;

    if (!networkViewModel.isConnected && !_hasHandledOfflineState) {
      _hasHandledOfflineState = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sensorReadingsViewModel.resetSensorReadings();
        //controlViewModel.resetControlState();
      });
    } else if (networkViewModel.isConnected) {
      _hasHandledOfflineState = false;
    }

    // Update animation when fanState changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnimation(controlViewModel.control.fanState);
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade50, Colors.orange.shade50],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Status Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Crop Dryer',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          controlViewModel.control.autoMode
                              ? 'Automatic Mode Active'
                              : 'Manual Control Mode',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        MdiIcons.sprout,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Temperature and Humidity Row
              Column(
                children: [
                  // Temperature card
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTemperatureColor(
                                temperature,
                                maxDryingTempViewModel.maxDryingTemp.value,
                              ).withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.thermostat,
                              size: 60,
                              color: _getTemperatureColor(
                                temperature,
                                maxDryingTempViewModel.maxDryingTemp.value,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Temperature',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${temperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _getTemperatureColor(
                                temperature,
                                maxDryingTempViewModel.maxDryingTemp.value,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Chip(
                            backgroundColor: _getTemperatureColor(
                              temperature,
                              maxDryingTempViewModel.maxDryingTemp.value,
                            ),
                            surfaceTintColor: Colors
                                .transparent, // Optional if you're already using backgroundColor
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: _getTemperatureColor(
                                  temperature,
                                  maxDryingTempViewModel.maxDryingTemp.value,
                                ),
                                width: 1.5, // Or any desired width
                              ),
                            ),
                            avatar: Icon(
                              _getIconStatusForTemperature(
                                temperature,
                                maxDryingTempViewModel.maxDryingTemp.value,
                              ),
                              color: Colors.white, // or any contrasting color
                            ),
                            label: Text(
                              '${_getTextStatusForTemperature(temperature, maxDryingTempViewModel.maxDryingTemp.value)} (${maxDryingTempViewModel.maxDryingTemp.value.round()}°C)',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors
                                    .white, // Or any contrast to background
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          TextButton.icon(
                            label: Text("Temperature settings"),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                "/temperatureSettings",
                              );
                            },
                            icon: Icon(
                              Icons.settings,
                              color: _getTemperatureColor(
                                temperature,
                                maxDryingTempViewModel.maxDryingTemp.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Humidity card
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getHumidityColor(
                                humidity,
                              ).withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.water_drop,
                              size: 60,
                              color: _getHumidityColor(humidity),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Humidity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${humidity.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _getHumidityColor(humidity),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            humidity > 70
                                ? 'High'
                                : humidity > 40
                                ? 'Optimal'
                                : 'Low',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor:
                          Colors.transparent, // Remove the line when expanded
                      expansionTileTheme: ExpansionTileThemeData(
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(),
                        collapsedShape: RoundedRectangleBorder(),
                      ),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      maintainState: true,
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          MdiIcons.flower,
                          size: 24,
                          color: Colors.green.shade700,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Crops',
                                  style: TextStyle(
                                    fontSize: 15.6,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow
                                      .visible, // Prevent text wrapping
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${selectedCrops.length} crop(s) selected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/cropSelection');
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: .8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Select Crops',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                      children: [
                        // Remove the manual divider since we're handling it with theme
                        if (selectedCrops.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  MdiIcons.informationOutline,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No crops selected. Select the crops you want to dry.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              Container(
                                height: 1,
                                color: Colors.grey.shade200,
                                margin: EdgeInsets.only(bottom: 16),
                              ),
                              ...selectedCrops.map<Widget>((crop) {
                                return Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          crop.iconData,
                                          size: 20,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              crop.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                            Text(
                                              'Range: ${crop.minTemp}°C - ${crop.maxTemp}°C',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _onDeleteCrop(crop);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Fan & Mode Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Fan Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: controlViewModel.control.fanState && networkViewModel.isConnected
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: RotationTransition(
                                turns: networkViewModel.isConnected ? _animation : AlwaysStoppedAnimation(0),
                                child: Icon(
                                  MdiIcons.fan,
                                  size: 32,
                                  color: controlViewModel.control.fanState && networkViewModel.isConnected
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drying Fan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  controlViewModel.control.fanState && networkViewModel.isConnected
                                      ? 'RUNNING'
                                      : 'STOPPED',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: controlViewModel.control.fanState && networkViewModel.isConnected
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: controlViewModel.control.fanState && networkViewModel.isConnected
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controlViewModel.control.fanState && networkViewModel.isConnected
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Mode Indicator
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: controlViewModel.control.autoMode
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controlViewModel.control.autoMode
                              ? Colors.blue.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controlViewModel.control.autoMode
                                ? MdiIcons.autoMode
                                : MdiIcons.handBackLeft,
                            size: 20,
                            color: controlViewModel.control.autoMode
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                          ),
                          SizedBox(width: 12),
                          Text(
                            controlViewModel.control.autoMode
                                ? 'Automatic Mode Active'
                                : 'Manual Control Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: controlViewModel.control.autoMode
                                  ? Colors.blue.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Control Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            onPressed: _onTurnOnFan,
                            icon: Icon(Icons.power),
                            text: 'Turn On Fan',
                            isEnabled: !controlViewModel.control.fanState,
                            gradientColors: [
                              Colors.green.shade600,
                              Colors.green.shade500,
                            ],
                            textColor: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),

                        Expanded(
                          child: GradientButton(
                            onPressed: _onTurnOffFan,
                            icon: Icon(Icons.power_off),
                            text: 'Turn Off Fan',
                            isEnabled: controlViewModel.control.fanState,
                            gradientColors: [
                              Colors.red.shade600,
                              Colors.red.shade500,
                            ],
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Auto Mode Button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: _onSwitchToAutomaticMode,
                        icon: Icon(Icons.autorenew),
                        text: 'Switch to Automatic Mode',
                        isEnabled: !controlViewModel.control.autoMode,
                        gradientColors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              //Light Control Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Light Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: controlViewModel.control.lightState && networkViewModel.isConnected
                                    ? Colors.yellow.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                MdiIcons.lightbulbOnOutline,
                                size: 32,
                                color: controlViewModel.control.lightState && networkViewModel.isConnected
                                    ? Colors.yellow.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dryer Light',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  controlViewModel.control.lightState && networkViewModel.isConnected
                                      ? 'ON'
                                      : 'OFF',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: controlViewModel.control.lightState && networkViewModel.isConnected
                                        ? Colors.yellow.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: controlViewModel.control.lightState && networkViewModel.isConnected
                                ? Colors.yellow.shade100
                                : Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controlViewModel.control.lightState && networkViewModel.isConnected
                                  ? Colors.yellow.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Light Control Button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: _onSwitchLight,
                        icon: Icon(
                          controlViewModel.control.lightState && networkViewModel.isConnected
                              ? Icons.lightbulb_outlined
                              : Icons.lightbulb,
                        ),
                        text: controlViewModel.control.lightState  && networkViewModel.isConnected
                            ? 'Turn Off Light'
                            : 'Turn On Light',
                        gradientColors: controlViewModel.control.lightState && networkViewModel.isConnected
                            ? [Colors.red.shade600, Colors.red.shade500]
                            : [Colors.green.shade600, Colors.green.shade500],
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _onTurnOnFan() {
    final networkViewModel = context.read<NetworkViewModel>();

    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }

    final controlViewModel = context.read<ControlViewModel>();

    if (controlViewModel.control.autoMode) {
      _showSwitchToManualMode(context, () {
        controlViewModel.updateControlState(autoMode: false, fanState: true);
      });
    } else {
      controlViewModel.updateControlState(autoMode: false, fanState: true);
    }
  }

  void _onTurnOffFan() {
    final networkViewModel = context.read<NetworkViewModel>();

    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }

    final controlViewModel = context.read<ControlViewModel>();

    if (controlViewModel.control.autoMode) {
      _showSwitchToManualMode(context, () {
        controlViewModel.updateControlState(autoMode: false, fanState: false);
      });
    } else {
      controlViewModel.updateControlState(autoMode: false, fanState: false);
    }
  }

  void _onSwitchToAutomaticMode() {
    final networkViewModel = context.read<NetworkViewModel>();

    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }

    final controlViewModel = context.read<ControlViewModel>();

    final maxDryingTempViewModel = context.read<MaxDryingTempViewModel>();

    final sensorReadigsViewModel = context.read<SensorReadingsViewModel>();

    _showSwitchToAutomaticMode(context, () {
      if (sensorReadigsViewModel.sensorReadings!.temperature >
          maxDryingTempViewModel.maxDryingTemp.value) {
        controlViewModel.updateControlState(autoMode: true, fanState: true);
      } else {
        controlViewModel.updateControlState(autoMode: true, fanState: false);
      }
    });
  }

  void _onSwitchLight() {
    final networkViewModel = context.read<NetworkViewModel>();

    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }

    final controlViewModel = context.read<ControlViewModel>();

    controlViewModel.updateControlState(
      lightState: !controlViewModel.control.lightState,
    );
  }

  void _onDeleteCrop(Crop crop) {
    final networkViewModel = context.read<NetworkViewModel>();
    if (!networkViewModel.isConnected) {
      _showNoInternetDialog(context);
      return;
    }
    final userViewModel = context.read<AuthViewModel>();

    _showDeleteCropDialog(context, crop.name, () {
      context.read<CropViewModel>().removeCrop(userViewModel.user!.id, crop);
    });
  }

  void _showDeleteCropDialog(
    BuildContext context,
    String cropName,
    VoidCallback onDelete,
  ) {
    showConfirmationDialog(
      context: context,
      title: 'Delete Crop',
      message:
          'Are you sure you want to delete "$cropName"? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmText: 'Delete',
      isDestructive: true,
      onConfirm: onDelete,
    );
  }

  void _showSwitchToAutomaticMode(
    BuildContext context,
    VoidCallback onSwitchToAutomaticMode,
  ) {
    showConfirmationDialog(
      context: context,
      title: 'Switch to Automatic Mode',
      message:
          'Are you sure you want to switch to automatic mode? This will stop the current manual control.',
      icon: Icons.autorenew,
      confirmText: 'Switch',
      onConfirm: onSwitchToAutomaticMode,
    );
  }

  void _showSwitchToManualMode(
    BuildContext context,
    VoidCallback onSwitchToManualMode,
  ) {
    showConfirmationDialog(
      context: context,
      title: 'Switch to Manual Mode',
      message:
          'Pressing the button will switch to manual mode. Are you sure you want to proceed? This will stop the current automatic control.',
      icon: MdiIcons.handBackLeft,
      confirmText: 'Switch',
      onConfirm: onSwitchToManualMode,
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
