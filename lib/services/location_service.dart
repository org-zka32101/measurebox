import 'package:geolocator/geolocator.dart';

/// A single latitude/longitude reading, used to tag a measurement with the
/// place it was recorded — useful for professionals/contractors who
/// record measurements across multiple job sites.
class LocationResult {
  final double latitude;
  final double longitude;

  const LocationResult({required this.latitude, required this.longitude});
}

/// Thrown when the user has declined location access (or disabled location
/// services entirely) so callers can show a specific, actionable message
/// instead of a generic error.
class LocationPermissionDeniedException implements Exception {
  final String message;
  const LocationPermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// One-shot GPS location lookup, backed by `geolocator` — a real,
/// well-supported cross-platform plugin (unlike illuminance, there is no
/// platform limitation here on either iOS or Android).
///
/// Unlike VibrationService (which streams continuously for the duration of
/// a measurement), a location tag only needs a single fix taken once, so
/// there's no start/stop pair here — just [getCurrentLocation].
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationPermissionDeniedException(
        '位置情報サービスが無効になっています。端末の設定で位置情報を有効にしてください。',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(
        '位置情報へのアクセスが許可されていません。設定アプリから位置情報の権限を許可してください。',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
