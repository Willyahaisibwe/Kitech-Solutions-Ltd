// dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:smart_crop_dryer/services/control_service.dart';
import 'package:smart_crop_dryer/services/crop_service.dart';
import 'package:smart_crop_dryer/services/device_info_service.dart';
import 'package:smart_crop_dryer/services/historical_reading_service.dart';
import 'package:smart_crop_dryer/services/network_service.dart';
import 'package:smart_crop_dryer/services/sensor_readings_service.dart';
import 'package:smart_crop_dryer/services/settings_service.dart';
import 'package:smart_crop_dryer/services/weather_api_service.dart';
import 'package:smart_crop_dryer/services/farm_control_service.dart';
import 'package:smart_crop_dryer/services/farm_sensor_readings_service.dart';
import 'package:smart_crop_dryer/services/farm_settings_service.dart';
import 'package:smart_crop_dryer/services/farm_device_info_service.dart';
import 'package:smart_crop_dryer/services/smart_home_control_service.dart';
import 'package:smart_crop_dryer/services/smart_home_device_info_service.dart';
import 'package:smart_crop_dryer/services/smart_home_sensors_service.dart';
import 'package:smart_crop_dryer/services/smart_home_settings_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // SERVICES - Smart Dryer
  getIt.registerSingleton<ControlService>(ControlService(null));
  getIt.registerSingleton<NetworkService>(NetworkService(null));
  getIt.registerSingleton<SensorReadingsService>(SensorReadingsService(null));
  getIt.registerSingleton<SettingsService>(SettingsService(null));
  getIt.registerSingleton<DeviceInfoService>(DeviceInfoService(null));
  getIt.registerSingleton<CropService>(CropService());
  getIt.registerSingleton<WeatherApiService>(WeatherApiService());
  getIt.registerSingleton<HistoricalReadingService>(
    HistoricalReadingService(null),
  );

  // SERVICES - Smart Farm
  getIt.registerSingleton<FarmControlService>(FarmControlService(null));
  getIt.registerSingleton<FarmSensorReadingsService>(
    FarmSensorReadingsService(null),
  );
  getIt.registerSingleton<FarmSettingsService>(FarmSettingsService(null));
  getIt.registerSingleton<FarmDeviceInfoService>(FarmDeviceInfoService(null));

  // SERVICES - Smart Home
  getIt.registerSingleton<SmartHomeControlService>(
    SmartHomeControlService(null),
  );
  getIt.registerSingleton<SmartHomeDeviceInfoService>(
    SmartHomeDeviceInfoService(null),
  );
  getIt.registerSingleton<SmartHomeSensorsService>(
    SmartHomeSensorsService(null),
  );
  getIt.registerSingleton<SmartHomeSettingsService>(
    SmartHomeSettingsService(null),
  );
}
