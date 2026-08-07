import 'dart:async';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'frequency_analysis_service.dart';

class AudioService {
  static const double referenceLevel = 1.0;
  static const int sampleRate = 44100;
  static const int frameSize = 4096;
  static const int updateIntervalMs = 100;

  // Frequency spectrum measurement config. 8192 samples @ 44.1kHz gives a
  // bin resolution of ~5.4Hz (sampleRate / frameSize), matching the app's
  // "medium precision" (±5Hz) target across the full 0-22050Hz (Nyquist)
  // range.
  static const int frequencyFrameSize = 8192;
  static const int frequencyUpdateIntervalMs = 150;

  Timer? _updateTimer;
  bool _isRecording = false;

  double _currentDb = 0.0;
  double _minDb = double.infinity;
  double _maxDb = 0.0;
  double _sumDb = 0.0;
  int _sampleCount = 0;

  DateTime? _startTime;
  List<double> _dbHistory = [];

  final FrequencyAnalysisService _frequencyAnalysisService =
      FrequencyAnalysisService();

  Timer? _frequencyTimer;
  bool _isFrequencyRecording = false;
  FrequencySpectrum? _currentSpectrum;

  DateTime? _frequencyStartTime;
  double _peakFrequencySum = 0.0;
  double _peakFrequencyMin = double.infinity;
  double _peakFrequencyMax = 0.0;
  int _frequencySampleCount = 0;
  final List<double> _peakFrequencyHistory = [];

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

    _currentDb = (baseDb + variation + noise).clamp(50.0, 120.0).toDouble();
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

  // ---------------------------------------------------------------------
  // Frequency spectrum measurement
  // ---------------------------------------------------------------------

  /// Starts periodic frequency spectrum analysis (0-22050Hz, ~5.4Hz
  /// resolution), reporting a new [FrequencySpectrum] roughly every
  /// [frequencyUpdateIntervalMs].
  ///
  /// NOTE: [_generatePcmFrame] currently *synthesizes* a plausible PCM frame
  /// rather than reading real hardware audio, mirroring how [startMeasurement]
  /// simulates dB above — there is no platform audio capture wired into this
  /// codebase yet. The FFT/analysis pipeline itself (windowing, FFT, peak
  /// detection, banding) is real and operates identically once real
  /// microphone PCM is plugged into [_generatePcmFrame]'s call site. See
  /// FREQUENCY_IMPLEMENTATION_PLAN.md for the native-capture follow-up.
  Future<void> startFrequencyMeasurement({
    required void Function(FrequencySpectrum spectrum) onSpectrumChange,
  }) async {
    if (_isFrequencyRecording) return;

    final hasPermission = await hasMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    _isFrequencyRecording = true;
    _currentSpectrum = null;
    _frequencyStartTime = DateTime.now();
    _peakFrequencySum = 0.0;
    _peakFrequencyMin = double.infinity;
    _peakFrequencyMax = 0.0;
    _frequencySampleCount = 0;
    _peakFrequencyHistory.clear();

    _frequencyTimer = Timer.periodic(
      Duration(milliseconds: frequencyUpdateIntervalMs),
      (_) {
        if (!_isFrequencyRecording) return;

        final pcmFrame = _generatePcmFrame(frequencyFrameSize);
        final spectrum = _frequencyAnalysisService.analyze(
          pcmFrame,
          sampleRate: sampleRate,
        );

        _currentSpectrum = spectrum;
        _recordPeakFrequencyStats(spectrum.peakFrequency);
        onSpectrumChange(spectrum);
      },
    );
  }

  Future<void> stopFrequencyMeasurement() async {
    if (!_isFrequencyRecording) return;
    _isFrequencyRecording = false;
    _frequencyTimer?.cancel();
  }

  void _recordPeakFrequencyStats(double peakFrequency) {
    _peakFrequencyHistory.add(peakFrequency);
    if (_frequencySampleCount == 0 || peakFrequency < _peakFrequencyMin) {
      _peakFrequencyMin = peakFrequency;
    }
    if (peakFrequency > _peakFrequencyMax) {
      _peakFrequencyMax = peakFrequency;
    }
    _peakFrequencySum += peakFrequency;
    _frequencySampleCount++;
  }

  /// Synthesizes a physically-plausible PCM frame (normalized to roughly
  /// [-1.0, 1.0]) standing in for real microphone input. Picks a random
  /// fundamental frequency (with small jitter) plus its first two harmonics
  /// and a broadband noise floor, so the resulting spectrum has a clear,
  /// varying peak — useful for exercising the full analysis/UI pipeline
  /// before real hardware capture is wired in.
  List<double> _generatePcmFrame(int frameCount) {
    final random = math.Random();
    const fundamentalOptions = [
      60.0, 120.0, 250.0, 440.0, 1000.0, 2000.0, 4000.0, 8000.0,
    ];
    final fundamental = fundamentalOptions[random.nextInt(fundamentalOptions.length)] +
        (random.nextDouble() - 0.5) * 8;
    const harmonicAmplitudes = [1.0, 0.5, 0.25];

    final samples = List<double>.filled(frameCount, 0.0);
    for (int n = 0; n < frameCount; n++) {
      double sample = 0.0;
      for (int h = 0; h < harmonicAmplitudes.length; h++) {
        final harmonicFreq = fundamental * (h + 1);
        sample += harmonicAmplitudes[h] *
            math.sin(2 * math.pi * harmonicFreq * n / sampleRate);
      }
      sample += (random.nextDouble() - 0.5) * 0.3;
      samples[n] = sample.clamp(-1.0, 1.0).toDouble();
    }
    return samples;
  }

  FrequencySpectrum? get currentSpectrum => _currentSpectrum;
  bool get isFrequencyRecording => _isFrequencyRecording;
  DateTime? getFrequencyStartTime() => _frequencyStartTime;
  List<double> getPeakFrequencyHistory() => _peakFrequencyHistory;

  double get peakFrequency => _currentSpectrum?.peakFrequency ?? 0.0;
  double get minPeakFrequency =>
      _peakFrequencyMin.isFinite ? _peakFrequencyMin : 0.0;
  double get maxPeakFrequency => _peakFrequencyMax;
  double get avgPeakFrequency =>
      _peakFrequencySum / math.max(_frequencySampleCount, 1);
}
