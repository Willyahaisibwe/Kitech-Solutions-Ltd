import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Streams position updates, but only emits a new event once the
  /// device has moved at least [distanceFilterMeters] from the last
  /// emitted point. This lets the OS do the distance filtering natively
  /// instead of us polling and comparing coordinates ourselves.
  Stream<Position> watchPosition({int distanceFilterMeters = 5000}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// Returns the device's current position, or throws if permission
  /// is denied or location services are turned off.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable it in app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }
}
