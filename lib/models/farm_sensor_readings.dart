class FarmSensorReadings {
  final double temperature1;
  final double temperature2;
  final double temperature3;

  final double humidity1;
  final double humidity2;
  final double humidity3;

  final double moisture1;
  final double moisture2;
  final double moisture3;

  FarmSensorReadings({
    required this.temperature1,
    required this.temperature2,
    required this.temperature3,
    required this.humidity1,
    required this.humidity2,
    required this.humidity3,
    required this.moisture1,
    required this.moisture2,
    required this.moisture3,
  });

  /// Average temperature across all probes
  double get averageTemperature =>
      (temperature1 + temperature2 + temperature3) / 3;

  /// Average humidity across all probes
  double get averageHumidity => (humidity1 + humidity2 + humidity3) / 3;

  /// Average moisture across all probes
  double get averageMoisture => (moisture1 + moisture2 + moisture3) / 3;

  factory FarmSensorReadings.fromJson(Map<String, dynamic> json) {
    final temperature = json['Temperature'] ?? {};
    final humidity = json['Humidity'] ?? {};
    final moisture = json['Moisture'] ?? {};

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return FarmSensorReadings(
      temperature1: toDouble(temperature['T1']),
      temperature2: toDouble(temperature['T2']),
      temperature3: toDouble(temperature['T3']),
      humidity1: toDouble(humidity['H1']),
      humidity2: toDouble(humidity['H2']),
      humidity3: toDouble(humidity['H3']),
      moisture1: toDouble(moisture['M1']),
      moisture2: toDouble(moisture['M2']),
      moisture3: toDouble(moisture['M3']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Temperature': {
        'T1': temperature1,
        'T2': temperature2,
        'T3': temperature3,
      },
      'Humidity': {'H1': humidity1, 'H2': humidity2, 'H3': humidity3},
      'Moisture': {'M1': moisture1, 'M2': moisture2, 'M3': moisture3},
    };
  }
}
