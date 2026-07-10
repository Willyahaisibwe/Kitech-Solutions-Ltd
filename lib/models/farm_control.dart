class FarmControl {
  final bool pumpState;
  final bool autoMode;

  FarmControl({required this.pumpState, required this.autoMode});

  factory FarmControl.fromMap(Map<String, dynamic> map) {
    return FarmControl(
      pumpState: map['PumpState'] ?? false,
      autoMode: map['autoMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'PumpState': pumpState, 'autoMode': autoMode};
  }

  FarmControl copyWith({bool? pumpState, bool? autoMode}) {
    return FarmControl(
      pumpState: pumpState ?? this.pumpState,
      autoMode: autoMode ?? this.autoMode,
    );
  }
}
