import 'dart:async';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import '../models/measurement_model.dart';

class AudioService {
  static const double referenceLevel = 1.0; // Reference level for dB calculation
  static const int sampleRate = 44100;
  static const int frameSize = 4096;
  static const int updateIntervalMs = 100;

  Timer? _updateTimer;
  bool _isRecording = false;

  double _currentDb = 0.0;
  double _minDb = 0.0;
  double _maxDb = 0.0;
  double _sumDb = 0.0;
  int _sampleCount = 0;

  DateTime? _startTime;

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<void> startMeasurement({
    required Function(double, double, double, double) onDBChange,
  }) async {
    if (_isRecording) return;

    final hasPermission = await hasMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    _isRecording = true;
    _currentDb = 0.0;
    _minDb = 0.0;
    _maxDb = 0.0;
    _sumDb = 0.0;
    _sampleCount = 0;
    _startTime = DateTime.now();

    // Simulate microphone input with random noise
    // In production, this would use actual microphone data via platform channels
    _updateTimer = Timer.periodic(
      Duration(milliseconds: updateIntervalMs),
      (_) {
        if (_isRecording) {
          _simulateAudioInput();
          onDBChange(_currentDb, _minDb, _maxDb, _sumDb / math.max(_sampleCount, 1));
        }
      },
    );
  }

  void _simulateAudioInput() {
    // Generate simulated audio samples (random noise)
    final List<int> samples = [];
    for (int i = 0; i < frameSize; i++) {
      // Random PCM sample between -32768 and 32767
      samples.add((math.Random().nextInt(65536) - 32768).toInt());
    }

    _calculateDB(samples);
  }

  void _calculateDB(List<int> samples) {
    if (samples.isEmpty) return;

    // Calculate RMS (Root Mean Square)
    double sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    final rms = math.sqrt(sum / samples.length);

    // Convert to dB (log10 = log * log10e)
    final db = 20 * math.log(rms / referenceLevel) * math.log10e;
    _currentDb = db.clamp(0.0, 130.0);

    // Update statistics
    if (_sampleCount == 0 || _currentDb < _minDb) {
      _minDb = _currentDb;
    }
    if (_currentDb > _maxDb) {
      _maxDb = _currentDb;
    }

    _sumDb += _currentDb;
    _sampleCount++;
  }

  Future<MeasurementModel> stopMeasurement() async {
    if (!_isRecording) {
      throw Exception('Recording not started');
    }

    _isRecording = false;
    _updateTimer?.cancel();

    final now = DateTime.now();
    final duration = now.difference(_startTime!);

    final measurement = MeasurementModel(
      id: '',
      projectId: '',
      type: 0,
      dbValue: _currentDb,
      dbMin: _minDb,
      dbAvg: _sumDb / math.max(_sampleCount, 1),
      dbMax: _maxDb,
      durationMs: duration.inMilliseconds,
      timestamp: now,
      calibrationOffset: 0.0,
      deviceInfo: 'iOS/Android',
    );

    return measurement;
  }

  void cancel() {
    _isRecording = false;
    _updateTimer?.cancel();
  }

  bool get isRecording => _isRecording;
  double get currentDb => _currentDb;
  double get minDb => _minDb;
  double get maxDb => _maxDb;
  double get avgDb => _sumDb / math.max(_sampleCount, 1);
}
