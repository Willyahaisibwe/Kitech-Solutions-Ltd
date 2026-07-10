class Control {
  final bool autoMode;
  final bool fanState;
  final bool lightState;

  Control({required this.autoMode, required this.fanState, required this.lightState});

  factory Control.fromMap(Map<String, dynamic> map) {
    return Control(
      autoMode: map['autoMode'] ?? false,
      fanState: map['fanState'] ?? false,
      lightState: map['lightState'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'autoMode': autoMode, 'fanState': fanState, 'lightState': lightState};
  }

  Control copyWith({bool? autoMode, bool? fanState, bool? lightState}) {
    return Control(
      autoMode: autoMode ?? this.autoMode,
      fanState: fanState ?? this.fanState,
      lightState: lightState ?? this.lightState,
    );
  }
}
