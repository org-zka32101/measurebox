import 'dart:async';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static const double referenceLevel = 1.0;
  static const int sampleRate = 44100;
  static const int frameSize = 4096;
  static const int updateIntervalMs = 100;

  Timer? _updateTimer;
  bool _isRecording = false;

  double _currentDb = 0.0;
  double _minDb = double.infinity;
  double _maxDb = 0.0;
  double _sumDb = 0.0;
  int _sampleCount = 0;

  DateTime? _startTime;
  List<double> _dbHistory = [];

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
    _minDb = double.infinity;
    _maxDb = 0.0;
    _sumDb = 0.0;
    _sampleCount = 0;
    _dbHistory = [];
    _startTime = DateTime.now();

    // Simulate environmental audio measurement with realistic variation
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

  Future<void> stopMeasurement() async {
    if (!_isRecording) return;
    _isRecording = false;
    _updateTimer?.cancel();
  }

  void _simulateAudioInput() {
    final baseDb = 70.0;
    final random = math.Random();
    final variation = random.nextDouble() * 10 - 5;
    final noise = (random.nextDouble() - 0.5) * 3;

    _currentDb = (baseDb + variation + noise).clamp(50.0, 120.0);
    _dbHistory.add(_currentDb);

    if (_sampleCount == 0 || _currentDb < _minDb) {
      _minDb = _currentDb;
    }
    if (_currentDb > _maxDb) {
      _maxDb = _currentDb;
    }

    _sumDb += _currentDb;
    _sampleCount++;
  }

  List<double> getDBHistory() => _dbHistory;
  DateTime? getStartTime() => _startTime;

  bool get isRecording => _isRecording;
  double get currentDb => _currentDb;
  double get minDb => _minDb;
  double get maxDb => _maxDb;
  double get avgDb => _sumDb / math.max(_sampleCount, 1);
}
