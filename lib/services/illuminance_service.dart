import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:light_sensor/light_sensor.dart';

/// Real-time illuminance (lux) measurement — **Android only**.
///
/// Unlike VibrationService/LocationService, there is no viable
/// cross-platform way to read the ambient light sensor: iOS has never
/// exposed a public API for it (Apple treats it as a private API, used
/// only for the OS's own auto-brightness), so no Flutter plugin can offer
/// real illuminance data there. Rather than fake iOS support with a
/// simulated value (as AudioService does for dB, clearly documented as
/// such), this feature is scoped to Android only, where `light_sensor`
/// reads the device's real `TYPE_LIGHT` sensor. [isAvailable] reports
/// `false` on every other platform and the UI hides the 照度 tab entirely
/// there — see MeasureScreen.
class IlluminanceService {
  StreamSubscription<int>? _subscription;
  bool _isRecording = false;

  int _currentLux = 0;
  int _minLux = 0;
  int _maxLux = 0;
  double _sumLux = 0;
  int _sampleCount = 0;
  DateTime? _startTime;

  /// True only on Android AND when the device actually reports a light
  /// sensor (some low-end/older devices lack one even on Android).
  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return await LightSensor.hasSensor();
    } catch (_) {
      // MissingPluginException or similar — treat as unavailable rather
      // than letting the error surface to the UI.
      return false;
    }
  }

  bool get isRecording => _isRecording;
  int get currentLux => _currentLux;
  int get minLux => _minLux;
  int get maxLux => _maxLux;
  double get avgLux => _sumLux / math.max(_sampleCount, 1);
  DateTime? get startTime => _startTime;

  Future<void> startMeasurement({
    required void Function(int current, int min, int max, double avg)
    onLuxChange,
    void Function(Object error)? onError,
  }) async {
    if (_isRecording) return;

    _isRecording = true;
    _currentLux = 0;
    _minLux = 0;
    _maxLux = 0;
    _sumLux = 0;
    _sampleCount = 0;
    _startTime = DateTime.now();

    _subscription = LightSensor.luxStream().listen(
      (lux) {
        if (!_isRecording) return;

        _currentLux = lux;
        if (_sampleCount == 0 || lux < _minLux) _minLux = lux;
        if (lux > _maxLux) _maxLux = lux;
        _sumLux += lux;
        _sampleCount++;

        onLuxChange(_currentLux, _minLux, _maxLux, avgLux);
      },
      onError: (Object error) {
        _isRecording = false;
        onError?.call(error);
      },
    );
  }

  Future<void> stopMeasurement() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _subscription?.cancel();
    _subscription = null;
  }
}
