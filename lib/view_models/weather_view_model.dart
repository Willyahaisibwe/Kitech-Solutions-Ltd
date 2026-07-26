import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/weather.dart';
import 'package:smart_crop_dryer/models/weather_forecast.dart';
import 'package:smart_crop_dryer/models/geo_location.dart';
import 'package:smart_crop_dryer/services/weather_api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_crop_dryer/services/location_service.dart';

class WeatherViewModel extends ChangeNotifier {
  WeatherApiService weatherApiService;
  LocationService locationService;
  Weather? _weather;
  List<ForecastEntry> _forecast = [];

  Weather? get weather => _weather;
  List<ForecastEntry> get forecast => _forecast;

  WeatherViewModel({
    required this.weatherApiService,
    LocationService? locationService,
  }) : locationService = locationService ?? LocationService();

  Future<void> fetchWeather(String city) async {
    _weather = await weatherApiService.fetchCurrentWeather(city);
    notifyListeners();
  }

  Future<void> fetchForecast(String city) async {
    _forecast = await weatherApiService.fetchForecast(city);
    notifyListeners();
  }

  Future<void> fetchWeatherForCurrentLocation() async {
    final position = await locationService.getCurrentPosition();

    _weather = await weatherApiService.fetchCurrentWeatherByCoords(
      position.latitude,
      position.longitude,
    );
    _forecast = await weatherApiService.fetchForecastByCoords(
      position.latitude,
      position.longitude,
    );
    notifyListeners();
  }

  /// Loads weather + forecast for a raw GPS position, used by the
  /// background location-watching stream (as opposed to the one-shot
  /// fetchWeatherForCurrentLocation, which reads the position itself).
  Future<void> fetchWeatherForPosition(Position position) async {
    _weather = await weatherApiService.fetchCurrentWeatherByCoords(
      position.latitude,
      position.longitude,
    );
    _forecast = await weatherApiService.fetchForecastByCoords(
      position.latitude,
      position.longitude,
    );
    notifyListeners();
  }

  /// Loads weather + forecast for a user-picked place (from search),
  /// rather than the device's GPS location.
  Future<void> fetchWeatherForLocation(GeoLocation location) async {
    _weather = await weatherApiService.fetchCurrentWeatherByCoords(
      location.lat,
      location.lon,
    );
    _forecast = await weatherApiService.fetchForecastByCoords(
      location.lat,
      location.lon,
    );
    notifyListeners();
  }

  Future<List<GeoLocation>> searchLocations(String query) {
    return weatherApiService.searchLocations(query);
  }
}
