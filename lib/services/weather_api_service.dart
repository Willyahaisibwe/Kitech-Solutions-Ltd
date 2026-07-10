import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_crop_dryer/models/weather.dart';

class WeatherApiService {
  final String apiKey = 'f71c9567cc021778f9857a51d3bd7365'; // Use environment variables instead!
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> fetchCurrentWeather(String city) async {
    final url = Uri.parse(
        '$baseUrl?q=$city&appid=$apiKey&units=metric');

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
}