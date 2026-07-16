class SmartHomeSensors {
  final bool motion;
  final double temperature;

  SmartHomeSensors({required this.motion, required this.temperature});

  factory SmartHomeSensors.fromMap(Map<String, dynamic> map) {
    return SmartHomeSensors(
      motion: map['Motion'] ?? false,
      temperature: (map['Temperature'] ?? 0.0) is double
          ? map['Temperature']
          : double.tryParse(map['Temperature'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'Motion': motion, 'Temperature': temperature};
  }
}
