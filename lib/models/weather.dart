class Weather {
  final double temperatureCelsius;
  final int humidityPercent;
  final String conditionMain; 
  final String conditionDescription; 
  final double windSpeedMps;
  final String cityName;
  
  Weather({
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.conditionMain,
    required this.conditionDescription,
    required this.windSpeedMps,
    required this.cityName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperatureCelsius: (json['main']['temp'] as num).toDouble(),
      humidityPercent: json['main']['humidity'] as int,
      conditionMain: json['weather'][0]['main'] as String,
      conditionDescription: json['weather'][0]['description'] as String,
      windSpeedMps: (json['wind']['speed'] as num).toDouble(),
      cityName: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureCelsius': temperatureCelsius,
      'humidityPercent': humidityPercent,
      'conditionMain': conditionMain,
      'conditionDescription': conditionDescription,
      'windSpeedMps': windSpeedMps,
      'cityName': cityName,
    };
  }
}