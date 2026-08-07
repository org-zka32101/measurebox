import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/colors.dart';
import '../../services/frequency_analysis_service.dart';

/// Real-time frequency spectrum bar display (0-22050Hz, log-scaled x-axis)
/// with a peak-frequency marker. Mirrors [DecibelGauge]'s CustomPaint-based
/// approach so it stays dependency-free and renders identically on every
/// platform.
class FrequencySpectrumWidget extends StatelessWidget {
  final FrequencySpectrum? spectrum;
  final int bandCount;

  const FrequencySpectrumWidget({
    super.key,
    required this.spectrum,
    this.bandCount = 32,
  });

  @override
  Widget build(BuildContext context) {
    final currentSpectrum = spectrum;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyLight),
      ),
      child: currentSpectrum == null
          ? Center(
              child: Text(
                '測定を開始すると周波数が表示されます',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                    ),
              ),
            )
          : CustomPaint(
              size: Size.infinite,
              painter: _SpectrumPainter(
                bands: FrequencyAnalysisService().downsampleToBands(
                  currentSpectrum,
                  bandCount: bandCount,
                ),
                peakFrequency: currentSpectrum.peakFrequency,
              ),
            ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<FrequencyPeak> bands;
  final double peakFrequency;

  _SpectrumPainter({required this.bands, required this.peakFrequency});

  static const double _minDb = FrequencyAnalysisService.minDb;
  static const double _labelAreaHeight = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final chartHeight = size.height - _labelAreaHeight;
    final barSlotWidth = size.width / bands.length;
    final barWidth = barSlotWidth * 0.7;

    for (int i = 0; i < bands.length; i++) {
      final band = bands[i];
      final normalized =
          ((band.magnitudeDb - _minDb) / (0 - _minDb)).clamp(0.0, 1.0).toDouble();
      final barHeight = normalized * chartHeight;

      final left = i * barSlotWidth + (barSlotWidth - barWidth) / 2;
      final rect = Rect.fromLTWH(
        left,
        chartHeight - barHeight,
        barWidth,
        barHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = _colorForNormalizedMagnitude(normalized),
      );
    }

    _drawFrequencyAxisLabels(canvas, size, chartHeight);
  }

  Color _colorForNormalizedMagnitude(double normalized) {
    if (normalized < 0.35) return primaryLight.withOpacity(0.5 + normalized);
    if (normalized < 0.65) return warningColor.withOpacity(0.7 + normalized * 0.3);
    return dangerColor.withOpacity(0.7 + normalized * 0.3);
  }

  void _drawFrequencyAxisLabels(Canvas canvas, Size size, double chartHeight) {
    const labelFreqs = [100, 1000, 10000];
    const minFreq = 20.0;
    const maxFreq = 22050.0;
    final logMin = math.log(minFreq);
    final logMax = math.log(maxFreq);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final freq in labelFreqs) {
      final position =
          (math.log(freq.toDouble()) - logMin) / (logMax - logMin);
      final x = position * size.width;

      final label = freq >= 1000 ? '${freq ~/ 1000}kHz' : '${freq}Hz';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: textSecondary, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter oldDelegate) {
    return oldDelegate.peakFrequency != peakFrequency ||
        oldDelegate.bands.length != bands.length;
  }
}
