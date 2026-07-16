class SmartHomeControl {
  final bool alarm;
  final bool fan;
  final bool light1;
  final bool light2;

  SmartHomeControl({
    required this.alarm,
    required this.fan,
    required this.light1,
    required this.light2,
  });

  factory SmartHomeControl.fromMap(Map<String, dynamic> map) {
    return SmartHomeControl(
      alarm: map['Alarm'] ?? false,
      fan: map['Fan'] ?? false,
      light1: map['Light1'] ?? false,
      light2: map['Light2'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'Alarm': alarm, 'Fan': fan, 'Light1': light1, 'Light2': light2};
  }

  SmartHomeControl copyWith({
    bool? alarm,
    bool? fan,
    bool? light1,
    bool? light2,
  }) {
    return SmartHomeControl(
      alarm: alarm ?? this.alarm,
      fan: fan ?? this.fan,
      light1: light1 ?? this.light1,
      light2: light2 ?? this.light2,
    );
  }
}
