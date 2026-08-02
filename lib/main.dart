import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/firebase_options.dart';
import 'package:smart_crop_dryer/page_switcher.dart';
import 'package:smart_crop_dryer/pages/account_settings_page.dart';
import 'package:smart_crop_dryer/pages/app__startup_handler.dart';
import 'package:smart_crop_dryer/pages/crop_selection_page.dart';
import 'package:smart_crop_dryer/pages/edit_user_info_page.dart';
import 'package:smart_crop_dryer/pages/historical_data_page.dart';
import 'package:smart_crop_dryer/pages/login_page.dart';
import 'package:smart_crop_dryer/pages/register_page.dart';
import 'package:smart_crop_dryer/pages/support_feedback_page.dart';
import 'package:smart_crop_dryer/pages/temperature_settings_page.dart';
import 'package:smart_crop_dryer/pages/weather_page.dart';
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
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';
import 'package:smart_crop_dryer/view_models/control_view_model.dart';
import 'package:smart_crop_dryer/view_models/crop_view_model.dart';
import 'package:smart_crop_dryer/view_models/device_info_view_model.dart';
import 'package:smart_crop_dryer/view_models/historical_view_model.dart';
import 'package:smart_crop_dryer/view_models/max_drying_temp_view_model.dart';
import 'package:smart_crop_dryer/view_models/network_view_model.dart';
import 'package:smart_crop_dryer/view_models/sensor_readings_view_model.dart';
import 'package:smart_crop_dryer/view_models/weather_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_control_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_sensor_readings_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_settings_view_model.dart';
import 'package:smart_crop_dryer/view_models/farm_device_info_view_model.dart';
import 'package:smart_crop_dryer/widgets/dependency_injection.dart';
import 'package:smart_crop_dryer/pages/farm_home_page.dart';
import 'package:smart_crop_dryer/pages/farm_settings_page.dart';
import 'package:smart_crop_dryer/view_models/farm_network_view_model.dart';
import 'package:smart_crop_dryer/pages/service_selector_page.dart';
import 'package:smart_crop_dryer/services/smart_home_control_service.dart';
import 'package:smart_crop_dryer/services/smart_home_device_info_service.dart';
import 'package:smart_crop_dryer/services/smart_home_sensors_service.dart';
import 'package:smart_crop_dryer/services/smart_home_settings_service.dart';
import 'package:smart_crop_dryer/view_models/smart_home_control_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_device_info_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_network_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_sensors_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_settings_view_model.dart';
import 'package:smart_crop_dryer/pages/smart_home_page.dart';
import 'package:smart_crop_dryer/pages/smart_home_settings_page.dart';
import 'package:smart_crop_dryer/services/app_update_service.dart';
import 'package:smart_crop_dryer/widgets/update_dialog.dart';
import 'package:smart_crop_dryer/pages/marketplace_page.dart';
import 'package:smart_crop_dryer/pages/my_listings_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setupDependencies();

  // Check for a new app version once per cold start, independent of
  // whatever screen the user ends up on (login, dashboard, etc.).
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final updateInfo = await AppUpdateService().checkForUpdate();
    if (updateInfo != null && updateInfo.updateAvailable) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        showUpdateDialog(context, updateInfo);
      }
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),

        // Proxy providers to update ViewModels based on AuthViewModel changes

        //ControlViewModel depends on AuthViewModel to get deviceId
        ChangeNotifierProxyProvider<AuthViewModel, ControlViewModel>(
          create: (_) =>
              ControlViewModel(controlService: getIt<ControlService>()),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.dryerDeviceId;
            if (deviceId != null &&
                (previous?.controlService.deviceId != deviceId)) {
              return ControlViewModel(
                controlService: getIt<ControlService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                ControlViewModel(controlService: getIt<ControlService>());
          },
        ),

        //NetworkViewModel depends on AuthViewModel to get deviceId
        ChangeNotifierProxyProvider<AuthViewModel, NetworkViewModel>(
          create: (_) =>
              NetworkViewModel(networkService: getIt<NetworkService>()),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.dryerDeviceId;
            if (deviceId != null &&
                (previous?.networkService.deviceId != deviceId)) {
              return NetworkViewModel(
                networkService: getIt<NetworkService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                NetworkViewModel(networkService: getIt<NetworkService>());
          },
        ),

        //SensorReadingsViewModel depends on AuthViewModel to get deviceId
        ChangeNotifierProxyProvider<AuthViewModel, SensorReadingsViewModel>(
          create: (_) => SensorReadingsViewModel(
            sensorService: getIt<SensorReadingsService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.dryerDeviceId;
            if (deviceId != null &&
                (previous?.sensorService.deviceId != deviceId)) {
              return SensorReadingsViewModel(
                sensorService: getIt<SensorReadingsService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                SensorReadingsViewModel(
                  sensorService: getIt<SensorReadingsService>(),
                );
          },
        ),

        //MaxDryingTempViewModel depends on AuthViewModel to get deviceId
        ChangeNotifierProxyProvider<AuthViewModel, MaxDryingTempViewModel>(
          create: (_) =>
              MaxDryingTempViewModel(settingsService: getIt<SettingsService>()),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.dryerDeviceId;
            if (deviceId != null &&
                (previous?.settingsService.deviceId != deviceId)) {
              return MaxDryingTempViewModel(
                settingsService: getIt<SettingsService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                MaxDryingTempViewModel(
                  settingsService: getIt<SettingsService>(),
                );
          },
        ),

        //DeviceInfoViewModel depends on AuthViewModel to get deviceId
        ChangeNotifierProxyProvider<AuthViewModel, DeviceInfoViewModel>(
          create: (_) => DeviceInfoViewModel(
            deviceInfoService: getIt<DeviceInfoService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.dryerDeviceId;
            if (deviceId != null &&
                (previous?.deviceInfoService.deviceId != deviceId)) {
              return DeviceInfoViewModel(
                deviceInfoService: getIt<DeviceInfoService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                DeviceInfoViewModel(
                  deviceInfoService: getIt<DeviceInfoService>(),
                );
          },
        ),

        //CropViewModel depends on AuthViewModel to get userId
        ChangeNotifierProxyProvider<AuthViewModel, CropViewModel>(
          create: (_) => CropViewModel(cropService: getIt<CropService>()),
          update: (_, authViewModel, previous) {
            final userId = authViewModel.user?.id;

            if (userId != null && (previous?.userId != userId)) {
              return CropViewModel(
                cropService: getIt<CropService>(),
                userId: userId,
              );
            }
            return previous ?? CropViewModel(cropService: getIt<CropService>());
          },
        ),

        ChangeNotifierProvider(
          create: (_) =>
              WeatherViewModel(weatherApiService: getIt<WeatherApiService>()),
        ),

        ChangeNotifierProxyProvider<AuthViewModel, HistoricalReadingViewModel>(
          create: (_) => HistoricalReadingViewModel(
            historyService: getIt<HistoricalReadingService>(),
          ),
          update: (_, authViewModel, previous) {
            final userId = authViewModel.user?.id;

            if (userId != null && (previous?.historyService.userId != userId)) {
              return HistoricalReadingViewModel(
                historyService: getIt<HistoricalReadingService>(),
                userId: userId,
              );
            }
            return previous ??
                HistoricalReadingViewModel(
                  historyService: getIt<HistoricalReadingService>(),
                );
          },
        ),

        // ===================== SMART FARM PROVIDERS =====================

        //FarmControlViewModel depends on AuthViewModel to get farmDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, FarmControlViewModel>(
          create: (_) =>
              FarmControlViewModel(controlService: getIt<FarmControlService>()),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.farmDeviceId;
            if (deviceId != null &&
                (previous?.controlService.deviceId != deviceId)) {
              return FarmControlViewModel(
                controlService: getIt<FarmControlService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                FarmControlViewModel(
                  controlService: getIt<FarmControlService>(),
                );
          },
        ),

        //FarmSensorReadingsViewModel depends on AuthViewModel to get farmDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, FarmSensorReadingsViewModel>(
          create: (_) => FarmSensorReadingsViewModel(
            sensorService: getIt<FarmSensorReadingsService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.farmDeviceId;
            if (deviceId != null &&
                (previous?.sensorService.deviceId != deviceId)) {
              return FarmSensorReadingsViewModel(
                sensorService: getIt<FarmSensorReadingsService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                FarmSensorReadingsViewModel(
                  sensorService: getIt<FarmSensorReadingsService>(),
                );
          },
        ),

        //FarmSettingsViewModel depends on AuthViewModel to get farmDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, FarmSettingsViewModel>(
          create: (_) => FarmSettingsViewModel(
            settingsService: getIt<FarmSettingsService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.farmDeviceId;
            if (deviceId != null &&
                (previous?.settingsService.deviceId != deviceId)) {
              return FarmSettingsViewModel(
                settingsService: getIt<FarmSettingsService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                FarmSettingsViewModel(
                  settingsService: getIt<FarmSettingsService>(),
                );
          },
        ),

        //FarmDeviceInfoViewModel depends on AuthViewModel to get farmDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, FarmDeviceInfoViewModel>(
          create: (_) => FarmDeviceInfoViewModel(
            deviceInfoService: getIt<FarmDeviceInfoService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.farmDeviceId;
            if (deviceId != null &&
                (previous?.deviceInfoService.deviceId != deviceId)) {
              return FarmDeviceInfoViewModel(
                deviceInfoService: getIt<FarmDeviceInfoService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                FarmDeviceInfoViewModel(
                  deviceInfoService: getIt<FarmDeviceInfoService>(),
                );
          },
        ),

        //FarmNetworkViewModel depends on AuthViewModel to get farmDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, FarmNetworkViewModel>(
          create: (_) => FarmNetworkViewModel(
            deviceInfoService: getIt<FarmDeviceInfoService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.farmDeviceId;
            if (deviceId != null &&
                (previous?.deviceInfoService.deviceId != deviceId)) {
              return FarmNetworkViewModel(
                deviceInfoService: getIt<FarmDeviceInfoService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                FarmNetworkViewModel(
                  deviceInfoService: getIt<FarmDeviceInfoService>(),
                );
          },
        ),
        // ===================== SMART HOME PROVIDERS =====================

        //SmartHomeControlViewModel depends on AuthViewModel to get homeDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, SmartHomeControlViewModel>(
          create: (_) => SmartHomeControlViewModel(
            controlService: getIt<SmartHomeControlService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.homeDeviceId;
            if (deviceId != null &&
                (previous?.controlService.deviceId != deviceId)) {
              return SmartHomeControlViewModel(
                controlService: getIt<SmartHomeControlService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                SmartHomeControlViewModel(
                  controlService: getIt<SmartHomeControlService>(),
                );
          },
        ),

        //SmartHomeSensorsViewModel depends on AuthViewModel to get homeDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, SmartHomeSensorsViewModel>(
          create: (_) => SmartHomeSensorsViewModel(
            sensorsService: getIt<SmartHomeSensorsService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.homeDeviceId;
            if (deviceId != null &&
                (previous?.sensorsService.deviceId != deviceId)) {
              return SmartHomeSensorsViewModel(
                sensorsService: getIt<SmartHomeSensorsService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                SmartHomeSensorsViewModel(
                  sensorsService: getIt<SmartHomeSensorsService>(),
                );
          },
        ),

        //SmartHomeSettingsViewModel depends on AuthViewModel to get homeDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, SmartHomeSettingsViewModel>(
          create: (_) => SmartHomeSettingsViewModel(
            settingsService: getIt<SmartHomeSettingsService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.homeDeviceId;
            if (deviceId != null &&
                (previous?.settingsService.deviceId != deviceId)) {
              return SmartHomeSettingsViewModel(
                settingsService: getIt<SmartHomeSettingsService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                SmartHomeSettingsViewModel(
                  settingsService: getIt<SmartHomeSettingsService>(),
                );
          },
        ),

        //SmartHomeDeviceInfoViewModel depends on AuthViewModel to get homeDeviceId
        ChangeNotifierProxyProvider<
          AuthViewModel,
          SmartHomeDeviceInfoViewModel
        >(
          create: (_) => SmartHomeDeviceInfoViewModel(
            deviceInfoService: getIt<SmartHomeDeviceInfoService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.homeDeviceId;
            if (deviceId != null &&
                (previous?.deviceInfoService.deviceId != deviceId)) {
              return SmartHomeDeviceInfoViewModel(
                deviceInfoService: getIt<SmartHomeDeviceInfoService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                SmartHomeDeviceInfoViewModel(
                  deviceInfoService: getIt<SmartHomeDeviceInfoService>(),
                );
          },
        ),

        //SmartHomeNetworkViewModel depends on AuthViewModel to get homeDeviceId
        ChangeNotifierProxyProvider<AuthViewModel, SmartHomeNetworkViewModel>(
          create: (_) => SmartHomeNetworkViewModel(
            deviceInfoService: getIt<SmartHomeDeviceInfoService>(),
          ),
          update: (_, authViewModel, previous) {
            final deviceId = authViewModel.user?.homeDeviceId;
            if (deviceId != null &&
                (previous?.deviceInfoService.deviceId != deviceId)) {
              return SmartHomeNetworkViewModel(
                deviceInfoService: getIt<SmartHomeDeviceInfoService>(),
                deviceId: deviceId,
              );
            }
            return previous ??
                SmartHomeNetworkViewModel(
                  deviceInfoService: getIt<SmartHomeDeviceInfoService>(),
                );
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const AppStartupHandler(),
      routes: {
        '/pageSwitcher': (context) => const PageSwitcher(),
        '/temperatureSettings': (context) => const TemperatureSettingsPage(),
        '/cropSelection': (context) => const CropSelectionPage(),
        '/accountSettings': (context) => const AccountSettingsPage(),
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/editUserInfo': (context) => const EditUserInfoPage(),
        '/weather': (context) => const WeatherPage(),
        '/historicalData': (context) => const HistoricalDataPage(),
        '/supportFeedback': (context) => const SupportFeedbackPage(),
        '/farmHome': (context) => const FarmHomePage(),
        '/farmSettings': (context) => const FarmSettingsPage(),
        '/serviceSelector': (context) => const ServiceSelectorPage(),
        '/homeHome': (context) => const SmartHomePage(),
        '/smartHomeSettings': (context) => const SmartHomeSettingsPage(),
        '/marketplace': (context) => const MarketplacePage(),
        '/myListings': (context) => const MyListingsPage(),
      },
    );
  }
}
