import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Real-time vibration measurement backed by the device's accelerometer.
///
/// Unlike [AudioService] (which simulates dB/frequency because no native
/// microphone capture is wired into this codebase yet — see its own doc
/// comment), this service reads genuine hardware sensor data via
/// `sensors_plus`, a well-supported cross-platform plugin that needs no
/// custom native code. `userAccelerometerEventStream()` already excludes
/// gravity, so the reported magnitude is the device's actual movement/
/// vibration, not a constant ~9.8 m/s² offset from gravity.
///
/// No runtime permission is required on either platform: raw accelerometer
/// access (unlike microphone, camera, or location) isn't gated behind an
/// OS permission prompt.
class VibrationService {
  // 20ms sampling (~50Hz) — fine enough to catch short vibration bursts
  // (e.g. impact from a hammer strike) without flooding the UI with
  // updates faster than a human can perceive.
  static const Duration samplingPeriod = SensorInterval.gameInterval;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  bool _isRecording = false;

  double _currentMagnitude = 0.0;
  double _minMagnitude = double.infinity;
  double _maxMagnitude = 0.0;
  double _sumMagnitude = 0.0;
  int _sampleCount = 0;
  DateTime? _startTime;

  /// Euclidean magnitude of the (gravity-excluded) acceleration vector —
  /// a single scalar "how much vibration right now" value, independent of
  /// which axis/orientation the device is being shaken along. Extracted as
  /// a pure function so the actual math is unit-testable without a real
  /// accelerometer or platform channel mocking.
  static double computeMagnitude(double x, double y, double z) {
    return math.sqrt(x * x + y * y + z * z);
  }

  bool get isRecording => _isRecording;
  double get currentMagnitude => _currentMagnitude;
  double get minMagnitude => _minMagnitude.isFinite ? _minMagnitude : 0.0;
  double get maxMagnitude => _maxMagnitude;
  double get avgMagnitude => _sumMagnitude / math.max(_sampleCount, 1);
  DateTime? get startTime => _startTime;

  /// Starts streaming accelerometer magnitude readings. [onMagnitudeChange]
  /// is called on every sensor event with (current, min, max, avg), mirroring
  /// AudioService.startMeasurement's callback shape so MeasureScreen can
  /// reuse the same pattern.
  ///
  /// [onError] is called if the stream errors — e.g. some low-end/old
  /// Android devices or emulators lack an accelerometer. sensors_plus won't
  /// crash the app in that case, but without an error handler here the
  /// measurement would silently hang with no readings and no feedback.
  Future<void> startMeasurement({
    required void Function(double current, double min, double max, double avg)
    onMagnitudeChange,
    void Function(Object error)? onError,
  }) async {
    if (_isRecording) return;

    _isRecording = true;
    _currentMagnitude = 0.0;
    _minMagnitude = double.infinity;
    _maxMagnitude = 0.0;
    _sumMagnitude = 0.0;
    _sampleCount = 0;
    _startTime = DateTime.now();

    _subscription = userAccelerometerEventStream(samplingPeriod: samplingPeriod)
        .listen(
          (event) {
            if (!_isRecording) return;

            final magnitude = computeMagnitude(event.x, event.y, event.z);
            _currentMagnitude = magnitude;
            if (_sampleCount == 0 || magnitude < _minMagnitude) {
              _minMagnitude = magnitude;
            }
            if (magnitude > _maxMagnitude) {
              _maxMagnitude = magnitude;
            }
            _sumMagnitude += magnitude;
            _sampleCount++;

            onMagnitudeChange(
              _currentMagnitude,
              minMagnitude,
              _maxMagnitude,
              avgMagnitude,
            );
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
