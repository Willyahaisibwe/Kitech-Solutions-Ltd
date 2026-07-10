import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/historical_reading.dart';
import 'package:smart_crop_dryer/services/historical_reading_service.dart';

class HistoricalReadingViewModel extends ChangeNotifier {
  final HistoricalReadingService historyService;

  List<HistoricalReading> _readings = [];
  bool _isLoading = false;
  Timer? _savingTimer;

  List<HistoricalReading> get readings => _readings;
  bool get isLoading => _isLoading;
  bool get isSavingActive => _savingTimer?.isActive ?? false;

  HistoricalReadingViewModel({required this.historyService, String? userId}) {
    if (userId != null && userId.isNotEmpty) {
      historyService.updateUserId(userId);
      // loadReadingsForToday();
      loadMockData();
    }
  }

  /// Start periodic saving (every 3 minutes)
  /// Pass current sensor readings and desired temp from your existing sources
  void startPeriodicSaving({
    required double Function() getCurrentTemperature,
    required double Function() getCurrentHumidity,
    required double Function() getDesiredTemp,
  }) {
    if (_savingTimer?.isActive ?? false) {
      print('⚠️ Periodic saving already active');
      return;
    }

    // Save immediately first
    _saveReading(
      temperature: getCurrentTemperature(),
      humidity: getCurrentHumidity(),
      desiredTemp: getDesiredTemp(),
    );

    // Then save every 3 minutes
    _savingTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _saveReading(
        temperature: getCurrentTemperature(),
        humidity: getCurrentHumidity(),
        desiredTemp: getDesiredTemp(),
      );
    });

    notifyListeners();
    print('▶️ Started periodic saving (every 3 minutes)');
  }

  /// Stop periodic saving
  void stopPeriodicSaving() {
    _savingTimer?.cancel();
    _savingTimer = null;
    notifyListeners();
    print('⏸️ Stopped periodic saving');
  }

  /// Save a reading to Firestore
  Future<void> _saveReading({
    required double temperature,
    required double humidity,
    required double desiredTemp,
  }) async {
    final reading = HistoricalReading(
      temperature: temperature,
      humidity: humidity,
      desiredTemp: desiredTemp,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await historyService.saveReading(reading);

      // Add to local list
      _readings.add(reading);
      notifyListeners();

      print('💾 Saved reading: ${reading.temperature}°C, ${reading.humidity}%');
    } catch (e) {
      print('❌ Failed to save reading: $e');
    }
  }

  /// Load readings for today
  Future<void> loadReadingsForToday() async {
    _isLoading = true;
    notifyListeners();

    try {
      _readings = await historyService.getReadingsForToday();
      print('📊 Loaded ${_readings.length} readings for today');
    } catch (e) {
      print('❌ Error loading readings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load readings for last N hours
  Future<void> loadReadingsForLastHours(int hours) async {
    _isLoading = true;
    notifyListeners();

    try {
      _readings = await historyService.getReadingsForLastHours(hours);
      print('📊 Loaded ${_readings.length} readings for last $hours hours');
    } catch (e) {
      print('❌ Error loading readings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load readings within timestamp range
  Future<void> loadReadings({int? startDate, int? endDate, int? limit}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _readings = await historyService.getReadings(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      print('📊 Loaded ${_readings.length} readings');
    } catch (e) {
      print('❌ Error loading readings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _savingTimer?.cancel();
    super.dispose();
  }




  ///MOCK DATA FOR TESTING PURPOSES ONLY

  // 12 data points simulating 12 hours of operation
  List<HistoricalReading> get mockReadings {
    final now = DateTime.now();
    final targetTemp = 50.0;
    final targetHumidity = 10.0;

    // This list simulates a temperature that starts below the target,
    // overshoots slightly, and then stabilizes around the target.
    return [
      // --- Start of Period (12 hours ago) ---
      _createReading(now, -11, 40.0, 75.0, targetTemp, targetHumidity),
      _createReading(now, -10, 42.5, 70.0, targetTemp, targetHumidity),
      _createReading(now, -9, 45.0, 65.0, targetTemp, targetHumidity),
      _createReading(now, -8, 47.5, 60.0, targetTemp, targetHumidity),
      _createReading(now, -7, 49.0, 55.0, targetTemp, targetHumidity),
      _createReading(
        now,
        -6,
        51.5,
        50.0,
        targetTemp,
        targetHumidity,
      ), // Overshoot
      // --- Stabilization Period ---
      _createReading(now, -5, 50.5, 45.0, targetTemp, targetHumidity),
      _createReading(now, -4, 49.8, 40.0, targetTemp, targetHumidity),
      _createReading(now, -3, 50.2, 35.0, targetTemp, targetHumidity),
      _createReading(now, -2, 50.0, 30.0, targetTemp, targetHumidity),
      _createReading(now, -1, 49.9, 25.0, targetTemp, targetHumidity),
      _createReading(
        now,
        0,
        50.1,
        20.0,
        targetTemp,
        targetHumidity,
      ), // Current time
      // --- End of Period (Now) ---
    ];
  }

  // Helper function to simplify creating data points
  HistoricalReading _createReading(
    DateTime now,
    int hoursOffset,
    double actualTemp,
    double actualHumidity,
    double desiredTemp,
    double
    desiredHumidity, // Not strictly needed for the chart, but good for completeness
  ) {
    return HistoricalReading(
      temperature: actualTemp,
      humidity: actualHumidity,
      desiredTemp: desiredTemp,
      timestamp: now.add(Duration(hours: hoursOffset)).millisecondsSinceEpoch,
    );
  }

  void loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Directly assign the static mock data
    _readings = mockReadings;

    // Reverse the list if you want the most recent data on the right side of the chart
    // (The chart usually handles this by iterating the list in order, but it's good practice)
    // If you generated it chronologically, no need to reverse.

    _isLoading = false;
    print('📊 Loaded ${_readings.length} mock readings for testing.');
    notifyListeners();
  }
}
