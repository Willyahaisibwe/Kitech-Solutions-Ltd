class FarmSettings {
  final double thresholdMoist;

  FarmSettings({required this.thresholdMoist});

  factory FarmSettings.fromMap(Map<String, dynamic> map) {
    return FarmSettings(
      thresholdMoist: (map['ThresholdMoist'] ?? 60).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'ThresholdMoist': thresholdMoist};
  }

  FarmSettings copyWith({double? thresholdMoist}) {
    return FarmSettings(
      thresholdMoist: thresholdMoist != null
          ? double.parse(thresholdMoist.toStringAsFixed(1))
          : this.thresholdMoist,
    );
  }
}
