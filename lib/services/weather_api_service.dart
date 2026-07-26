import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_crop_dryer/models/weather.dart';
import 'package:smart_crop_dryer/models/weather_forecast.dart';
import 'package:smart_crop_dryer/models/geo_location.dart';

class WeatherApiService {
  final String apiKey =
      'f71c9567cc021778f9857a51d3bd7365'; // Use environment variables instead!
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  final String geocodeUrl = 'https://api.openweathermap.org/geo/1.0/direct';

  Future<Weather> fetchCurrentWeather(String city) async {
    final url = Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<ForecastEntry>> fetchForecast(String city) async {
    final url = Uri.parse('$forecastUrl?q=$city&appid=$apiKey&units=metric');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final list = decoded['list'] as List;
        return list
            .map(
              (entry) => ForecastEntry.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Weather> fetchCurrentWeatherByCoords(double lat, double lon) async {
    final url = Uri.parse(
      '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<ForecastEntry>> fetchForecastByCoords(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      '$forecastUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final list = decoded['list'] as List;
        return list
            .map(
              (entry) => ForecastEntry.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Searches for places by name, biased toward Uganda ("UG").
  /// Works for cities, towns, and many named localities (e.g. "Matugga",
  /// "Nakawa"), depending on how granular OpenWeatherMap's geocoder is
  /// for that name.
  Future<List<GeoLocation>> searchLocations(String query) async {
    final url = Uri.parse(
      '$geocodeUrl?q=${Uri.encodeComponent(query)},UG&limit=8&appid=$apiKey',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List;
        return decoded
            .map((entry) => GeoLocation.fromJson(entry as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to search locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
