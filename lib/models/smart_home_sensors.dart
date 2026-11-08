class SmartHomeSensors {
  final bool motion;
  final double temperature;
  final bool relayed;
  final String? relayedBy;

  SmartHomeSensors({
    required this.motion,
    required this.temperature,
    this.relayed = false,
    this.relayedBy,
  });

  factory SmartHomeSensors.fromMap(Map<String, dynamic> map) {
    return SmartHomeSensors(
      motion: map['Motion'] ?? false,
      temperature: (map['Temperature'] ?? 0.0) is double
          ? map['Temperature']
          : double.tryParse(map['Temperature'].toString()) ?? 0.0,
      relayed: map['relayed'] ?? false,
      relayedBy: map['relayedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Motion': motion,
      'Temperature': temperature,
      'relayed': relayed,
      'relayedBy': relayedBy,
    };
  }
}
