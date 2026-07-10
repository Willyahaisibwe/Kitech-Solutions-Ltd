import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/weather.dart';
import 'package:smart_crop_dryer/services/weather_api_service.dart';

class WeatherViewModel  extends ChangeNotifier
{
  WeatherApiService weatherApiService;
  Weather? _weather;

  Weather? get weather => _weather;

  WeatherViewModel({required this.weatherApiService});

  Future<void> fetchWeather(String city) async {
    _weather = await weatherApiService.fetchCurrentWeather(city);
    notifyListeners();
  }



}