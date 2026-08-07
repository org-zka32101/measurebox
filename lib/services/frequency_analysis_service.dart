import 'dart:math' as math;
import 'dart:typed_data';

/// A single detected frequency peak in the spectrum.
class FrequencyPeak {
  final double frequency;
  final double magnitudeDb;

  const FrequencyPeak(this.frequency, this.magnitudeDb);
}

/// Aggregate statistics computed over a spectrum snapshot.
class FrequencyStats {
  /// Magnitude-weighted average frequency (spectral centroid), in Hz.
  final double avgFrequency;
  final double maxMagnitudeDb;
  final double minMagnitudeDb;

  const FrequencyStats({
    required this.avgFrequency,
    required this.maxMagnitudeDb,
    required this.minMagnitudeDb,
  });
}

/// One analyzed spectrum snapshot: frequency bins, their magnitudes, and
/// derived peak/stat information.
class FrequencySpectrum {
  /// Frequency (Hz) for each bin, 0..Nyquist, ascending.
  final List<double> frequencies;

  /// Magnitude (dB, clamped to [FrequencyAnalysisService.minDb, 0]) per bin,
  /// aligned index-for-index with [frequencies].
  final List<double> magnitudesDb;

  final double peakFrequency;
  final double peakMagnitudeDb;

  /// Up to [FrequencyAnalysisService.topFrequencyCount] distinct local-maxima
  /// peaks, sorted by magnitude descending.
  final List<FrequencyPeak> topFrequencies;

  final FrequencyStats statistics;

  const FrequencySpectrum({
    required this.frequencies,
    required this.magnitudesDb,
    required this.peakFrequency,
    required this.peakMagnitudeDb,
    required this.topFrequencies,
    required this.statistics,
  });
}

/// Pure-Dart FFT-based frequency spectrum analyzer.
///
/// Implements an iterative radix-2 Cooley-Tukey FFT with a Hann window, so
/// it has no native/platform dependency and works identically on every
/// platform Flutter targets. Input PCM must be power-of-two-padded internally
/// (handled automatically by [analyze]).
///
/// Frequency resolution ("bin width") is `sampleRate / fftSize`. For the
/// default 44.1kHz / 8192-sample frame used by [AudioService] this is
/// ~5.4Hz, matching the app's "medium precision" (±5Hz) target.
class FrequencyAnalysisService {
  /// Floor for magnitude values, in dB. Anything quieter is clamped here so
  /// silence doesn't produce -infinity.
  static const double minDb = -90.0;

  /// Maximum number of distinct peaks reported in [FrequencySpectrum.topFrequencies].
  static const int topFrequencyCount = 5;

  /// Minimum spacing (Hz) enforced between reported peaks, so a single loud
  /// tone doesn't get reported as several adjacent "peaks".
  static const double minPeakSeparationHz = 40.0;

  /// A peak must exceed the noise floor by this many dB to be reported.
  static const double minPeakProminenceDb = 10.0;

  /// Runs FFT-based spectrum analysis on a frame of PCM samples.
  ///
  /// [pcmSamples] should be normalized roughly to [-1.0, 1.0]. [sampleRate]
  /// is the sampling rate the PCM was captured/generated at (Hz).
  FrequencySpectrum analyze(
    List<double> pcmSamples, {
    required int sampleRate,
  }) {
    if (pcmSamples.isEmpty) {
      throw ArgumentError('pcmSamples must not be empty');
    }

    final n = _nextPowerOfTwo(pcmSamples.length);
    final re = Float64List(n);
    final im = Float64List(n);

    // Apply a Hann window while copying into the (zero-padded) FFT buffer.
    // Windowing reduces spectral leakage from the frame boundary.
    final windowLength = pcmSamples.length;
    for (int i = 0; i < windowLength; i++) {
      final window = windowLength > 1
          ? 0.5 - 0.5 * math.cos(2 * math.pi * i / (windowLength - 1))
          : 1.0;
      re[i] = pcmSamples[i] * window;
    }

    _fftInPlace(re, im);

    // Only the first half (up to Nyquist) is meaningful for real input.
    final binCount = n ~/ 2;
    final freqResolution = sampleRate / n;
    final frequencies = List<double>.generate(
      binCount,
      (i) => i * freqResolution,
      growable: false,
    );

    // Hann window has a coherent gain of 0.5, so we compensate by doubling;
    // combined with the standard 2/n normalization this becomes 4/n, but we
    // keep it simple and perceptually-tuned via the /  (n/2) below.
    final magnitudesDb = List<double>.filled(binCount, minDb, growable: false);
    double peakMag = minDb;
    int peakIndex = 0;

    for (int i = 0; i < binCount; i++) {
      final magnitude = math.sqrt(re[i] * re[i] + im[i] * im[i]) / (n / 2);
      final db = magnitude > 0 ? 20 * _log10(magnitude) : minDb;
      final clamped = db < minDb ? minDb : (db > 0 ? 0.0 : db);
      magnitudesDb[i] = clamped;
      if (clamped > peakMag) {
        peakMag = clamped;
        peakIndex = i;
      }
    }

    final topFrequencies = _findTopPeaks(frequencies, magnitudesDb);
    final stats = _computeStats(frequencies, magnitudesDb);

    return FrequencySpectrum(
      frequencies: frequencies,
      magnitudesDb: magnitudesDb,
      peakFrequency: frequencies.isEmpty ? 0.0 : frequencies[peakIndex],
      peakMagnitudeDb: peakMag,
      topFrequencies: topFrequencies,
      statistics: stats,
    );
  }

  /// Downsamples a full-resolution spectrum into [bandCount] display bands
  /// (log-spaced by default, matching how spectrum analyzers/equalizers
  /// typically present audio so low-frequency detail isn't crushed against
  /// high-frequency detail in a linear layout).
  ///
  /// Returns a list of `(centerFrequencyHz, magnitudeDb)` bands, ascending.
  List<FrequencyPeak> downsampleToBands(
    FrequencySpectrum spectrum, {
    int bandCount = 32,
    bool logScale = true,
  }) {
    if (spectrum.frequencies.isEmpty || bandCount <= 0) return [];

    final minFreq = math.max(spectrum.frequencies.first, 20.0);
    final maxFreq = spectrum.frequencies.last;
    final bands = <FrequencyPeak>[];

    for (int b = 0; b < bandCount; b++) {
      final double lowFreq;
      final double highFreq;
      if (logScale) {
        final logMin = math.log(minFreq);
        final logMax = math.log(maxFreq);
        lowFreq = math.exp(logMin + (logMax - logMin) * b / bandCount);
        highFreq = math.exp(logMin + (logMax - logMin) * (b + 1) / bandCount);
      } else {
        lowFreq = maxFreq * b / bandCount;
        highFreq = maxFreq * (b + 1) / bandCount;
      }

      double maxDbInBand = minDb;
      for (int i = 0; i < spectrum.frequencies.length; i++) {
        final f = spectrum.frequencies[i];
        if (f >= lowFreq && f < highFreq) {
          if (spectrum.magnitudesDb[i] > maxDbInBand) {
            maxDbInBand = spectrum.magnitudesDb[i];
          }
        }
      }

      bands.add(FrequencyPeak((lowFreq + highFreq) / 2, maxDbInBand));
    }

    return bands;
  }

  List<FrequencyPeak> _findTopPeaks(
    List<double> frequencies,
    List<double> magnitudesDb,
  ) {
    final candidates = <FrequencyPeak>[];

    for (int i = 1; i < magnitudesDb.length - 1; i++) {
      final isLocalMax = magnitudesDb[i] >= magnitudesDb[i - 1] &&
          magnitudesDb[i] >= magnitudesDb[i + 1];
      final isProminent = magnitudesDb[i] > minDb + minPeakProminenceDb;
      if (isLocalMax && isProminent) {
        candidates.add(FrequencyPeak(frequencies[i], magnitudesDb[i]));
      }
    }

    candidates.sort((a, b) => b.magnitudeDb.compareTo(a.magnitudeDb));

    final result = <FrequencyPeak>[];
    for (final candidate in candidates) {
      final tooClose = result.any(
        (r) => (r.frequency - candidate.frequency).abs() < minPeakSeparationHz,
      );
      if (!tooClose) {
        result.add(candidate);
      }
      if (result.length >= topFrequencyCount) break;
    }

    return result;
  }

  FrequencyStats _computeStats(
    List<double> frequencies,
    List<double> magnitudesDb,
  ) {
    double weightedSum = 0.0;
    double weightSum = 0.0;
    double maxDb = minDb;
    double minDbFound = 0.0;

    for (int i = 0; i < magnitudesDb.length; i++) {
      // Convert back to a linear weight so the centroid is magnitude-weighted
      // rather than skewed by the dB log scale.
      final linear = math.pow(10, magnitudesDb[i] / 20).toDouble();
      weightedSum += frequencies[i] * linear;
      weightSum += linear;
      if (magnitudesDb[i] > maxDb) maxDb = magnitudesDb[i];
      if (magnitudesDb[i] < minDbFound) minDbFound = magnitudesDb[i];
    }

    final avgFrequency = weightSum > 0 ? weightedSum / weightSum : 0.0;

    return FrequencyStats(
      avgFrequency: avgFrequency,
      maxMagnitudeDb: maxDb,
      minMagnitudeDb: minDbFound,
    );
  }

  int _nextPowerOfTwo(int n) {
    int p = 1;
    while (p < n) {
      p <<= 1;
    }
    return p;
  }

  double _log10(double x) => math.log(x) / math.ln10;

  /// Iterative, in-place radix-2 Cooley-Tukey FFT. `re`/`im` must have a
  /// power-of-two length; `re` holds the (windowed) real input on entry and
  /// the real part of the spectrum on exit, `im` starts as zeros and holds
  /// the imaginary part on exit.
  void _fftInPlace(Float64List re, Float64List im) {
    final n = re.length;
    if (n <= 1) return;

    // Bit-reversal permutation.
    int j = 0;
    for (int i = 1; i < n; i++) {
      int bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final tempRe = re[i];
        re[i] = re[j];
        re[j] = tempRe;
        final tempIm = im[i];
        im[i] = im[j];
        im[j] = tempIm;
      }
    }

    // Iterative Danielson-Lanczos butterfly.
    for (int len = 2; len <= n; len <<= 1) {
      final angle = -2 * math.pi / len;
      final wr = math.cos(angle);
      final wi = math.sin(angle);
      final half = len >> 1;

      for (int i = 0; i < n; i += len) {
        double curWr = 1.0;
        double curWi = 0.0;

        for (int k = 0; k < half; k++) {
          final evenIndex = i + k;
          final oddIndex = i + k + half;

          final evenRe = re[evenIndex];
          final evenIm = im[evenIndex];
          final oddRe = re[oddIndex] * curWr - im[oddIndex] * curWi;
          final oddIm = re[oddIndex] * curWi + im[oddIndex] * curWr;

          re[evenIndex] = evenRe + oddRe;
          im[evenIndex] = evenIm + oddIm;
          re[oddIndex] = evenRe - oddRe;
          im[oddIndex] = evenIm - oddIm;

          final nextWr = curWr * wr - curWi * wi;
          final nextWi = curWr * wi + curWi * wr;
          curWr = nextWr;
          curWi = nextWi;
        }
      }
    }
  }
}
