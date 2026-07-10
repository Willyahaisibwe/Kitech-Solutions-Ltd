class HistoricalReading {
  final double temperature;
  final double humidity;
  final double desiredTemp;
  final int timestamp;

  HistoricalReading({
    required this.temperature,
    required this.humidity,
    required this.desiredTemp,
    required this.timestamp,
  });

  factory HistoricalReading.fromMap(Map<String, dynamic> map) {
    return HistoricalReading(
      temperature: (map['temperature'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      desiredTemp: (map['desiredTemp'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'desiredTemp': desiredTemp,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'HistoricalReading(temp: $temperature°C, humidity: $humidity%, desiredTemp: $desiredTemp°C, timestamp: $timestamp)';
  }
}