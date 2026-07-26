class ForecastEntry {
  final DateTime dateTime;
  final double temperatureCelsius;
  final int humidityPercent;
  final String conditionMain;
  final String conditionDescription;
  final double windSpeedMps;
  final double probabilityOfPrecipitation; // 0.0–1.0

  ForecastEntry({
    required this.dateTime,
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.conditionMain,
    required this.conditionDescription,
    required this.windSpeedMps,
    required this.probabilityOfPrecipitation,
  });

  factory ForecastEntry.fromJson(Map<String, dynamic> json) {
    return ForecastEntry(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
        isUtc: true,
      ),
      temperatureCelsius: (json['main']['temp'] as num).toDouble(),
      humidityPercent: json['main']['humidity'] as int,
      conditionMain: json['weather'][0]['main'] as String,
      conditionDescription: json['weather'][0]['description'] as String,
      windSpeedMps: (json['wind']['speed'] as num).toDouble(),
      probabilityOfPrecipitation: (json['pop'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'temperatureCelsius': temperatureCelsius,
      'humidityPercent': humidityPercent,
      'conditionMain': conditionMain,
      'conditionDescription': conditionDescription,
      'windSpeedMps': windSpeedMps,
      'probabilityOfPrecipitation': probabilityOfPrecipitation,
    };
  }
}
