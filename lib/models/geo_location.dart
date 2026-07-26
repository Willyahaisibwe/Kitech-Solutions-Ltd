class GeoLocation {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  GeoLocation({
    required this.name,
    this.state,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  /// e.g. "Matugga, Wakiso, UG" or "Kampala, UG" if no state given.
  String get displayLabel {
    final parts = [
      name,
      if (state != null && state!.isNotEmpty) state,
      country,
    ];
    return parts.join(', ');
  }
}
