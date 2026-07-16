class SmartHomeSettings {
  final bool alarmEnabled;
  final bool autoLight;
  final double thresholdTemp;

  SmartHomeSettings({
    required this.alarmEnabled,
    required this.autoLight,
    required this.thresholdTemp,
  });

  factory SmartHomeSettings.fromMap(Map<String, dynamic> map) {
    return SmartHomeSettings(
      alarmEnabled: map['AlarmEnabled'] ?? false,
      autoLight: map['AutoLight'] ?? false,
      thresholdTemp: (map['ThresholdTemp'] ?? 30) is double
          ? map['ThresholdTemp']
          : double.tryParse(map['ThresholdTemp'].toString()) ?? 30.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'AlarmEnabled': alarmEnabled,
      'AutoLight': autoLight,
      'ThresholdTemp': thresholdTemp,
    };
  }

  SmartHomeSettings copyWith({
    bool? alarmEnabled,
    bool? autoLight,
    double? thresholdTemp,
  }) {
    return SmartHomeSettings(
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      autoLight: autoLight ?? this.autoLight,
      thresholdTemp: thresholdTemp ?? this.thresholdTemp,
    );
  }
}
