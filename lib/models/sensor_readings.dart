class SensorReadings 
{
  final double temperature;
  final double humidity;

  SensorReadings({
    required this.temperature,
    required this.humidity,
  });

  factory SensorReadings.fromJson(Map<String, dynamic> json) {
    return SensorReadings(
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
    );
  }
}