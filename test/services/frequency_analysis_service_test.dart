import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/services/frequency_analysis_service.dart';

/// Generates a normalized PCM sine wave at [frequency]Hz, sampled at
/// [sampleRate]Hz for [sampleCount] samples.
List<double> _generateSineWave({
  required double frequency,
  required int sampleRate,
  required int sampleCount,
  double amplitude = 1.0,
}) {
  return List<double>.generate(
    sampleCount,
    (n) => amplitude * math.sin(2 * math.pi * frequency * n / sampleRate),
  );
}

void main() {
  group('FrequencyAnalysisService', () {
    late FrequencyAnalysisService service;
    const sampleRate = 44100;
    const frameSize = 8192; // matches AudioService.frequencyFrameSize

    setUp(() {
      service = FrequencyAnalysisService();
    });

    test('detects the peak frequency of a pure 1000Hz tone within bin resolution', () {
      final pcm = _generateSineWave(
        frequency: 1000.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );

      final spectrum = service.analyze(pcm, sampleRate: sampleRate);
      final binResolution = sampleRate / frameSize; // ~5.4Hz

      expect(spectrum.peakFrequency, closeTo(1000.0, binResolution));
    });

    test('detects the peak frequency of a pure 440Hz tone (concert A) within bin resolution', () {
      final pcm = _generateSineWave(
        frequency: 440.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );

      final spectrum = service.analyze(pcm, sampleRate: sampleRate);
      final binResolution = sampleRate / frameSize;

      expect(spectrum.peakFrequency, closeTo(440.0, binResolution));
    });

    test('spectrum covers 0..Nyquist with ascending frequencies', () {
      final pcm = _generateSineWave(
        frequency: 2000.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );

      final spectrum = service.analyze(pcm, sampleRate: sampleRate);

      expect(spectrum.frequencies.first, 0.0);
      expect(spectrum.frequencies.last, lessThanOrEqualTo(sampleRate / 2));
      for (int i = 1; i < spectrum.frequencies.length; i++) {
        expect(spectrum.frequencies[i], greaterThan(spectrum.frequencies[i - 1]));
      }
      expect(spectrum.frequencies.length, spectrum.magnitudesDb.length);
    });

    test('magnitudes are clamped to [minDb, 0]', () {
      final pcm = _generateSineWave(
        frequency: 500.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );

      final spectrum = service.analyze(pcm, sampleRate: sampleRate);

      for (final db in spectrum.magnitudesDb) {
        expect(db, greaterThanOrEqualTo(FrequencyAnalysisService.minDb));
        expect(db, lessThanOrEqualTo(0.0));
      }
    });

    test('a two-tone signal surfaces both frequencies among the top peaks', () {
      final toneA = _generateSineWave(
        frequency: 300.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );
      final toneB = _generateSineWave(
        frequency: 3000.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );
      final mixed = List<double>.generate(
        frameSize,
        (i) => (toneA[i] + toneB[i]) / 2,
      );

      final spectrum = service.analyze(mixed, sampleRate: sampleRate);
      final binResolution = sampleRate / frameSize;

      expect(spectrum.topFrequencies.length, greaterThanOrEqualTo(2));
      final foundA = spectrum.topFrequencies
          .any((p) => (p.frequency - 300.0).abs() < binResolution * 2);
      final foundB = spectrum.topFrequencies
          .any((p) => (p.frequency - 3000.0).abs() < binResolution * 2);
      expect(foundA, isTrue, reason: 'expected a peak near 300Hz');
      expect(foundB, isTrue, reason: 'expected a peak near 3000Hz');
    });

    test('handles non-power-of-two input lengths by zero-padding internally', () {
      final pcm = _generateSineWave(
        frequency: 1000.0,
        sampleRate: sampleRate,
        sampleCount: 5000, // not a power of two
      );

      final spectrum = service.analyze(pcm, sampleRate: sampleRate);

      // next power of two >= 5000 is 8192
      expect(spectrum.frequencies.length, 8192 ~/ 2);
    });

    test('throws for empty input', () {
      expect(
        () => service.analyze(<double>[], sampleRate: sampleRate),
        throwsArgumentError,
      );
    });

    test('spectral centroid stats are within the analyzed frequency range', () {
      final pcm = _generateSineWave(
        frequency: 1000.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );

      final spectrum = service.analyze(pcm, sampleRate: sampleRate);

      expect(spectrum.statistics.avgFrequency, greaterThanOrEqualTo(0.0));
      expect(spectrum.statistics.avgFrequency, lessThanOrEqualTo(sampleRate / 2));
      expect(spectrum.statistics.maxMagnitudeDb, spectrum.peakMagnitudeDb);
    });

    test('downsampleToBands returns the requested number of log-spaced bands', () {
      final pcm = _generateSineWave(
        frequency: 1000.0,
        sampleRate: sampleRate,
        sampleCount: frameSize,
      );
      final spectrum = service.analyze(pcm, sampleRate: sampleRate);

      final bands = service.downsampleToBands(spectrum, bandCount: 32);

      expect(bands.length, 32);
      // Bands should be ascending in center frequency.
      for (int i = 1; i < bands.length; i++) {
        expect(bands[i].frequency, greaterThan(bands[i - 1].frequency));
      }
    });

    test('silence produces a spectrum floored at minDb', () {
      final silence = List<double>.filled(frameSize, 0.0);

      final spectrum = service.analyze(silence, sampleRate: sampleRate);

      expect(spectrum.peakMagnitudeDb, FrequencyAnalysisService.minDb);
      for (final db in spectrum.magnitudesDb) {
        expect(db, FrequencyAnalysisService.minDb);
      }
    });
  });
}
