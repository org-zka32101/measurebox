import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../services/frequency_analysis_service.dart';

/// Digital readout of the current frequency spectrum: peak frequency (large
/// display, matching [DecibelGauge]'s value styling), spectral-centroid
/// average, and up to five dominant secondary frequencies.
class FrequencyDetailsCard extends StatelessWidget {
  final FrequencySpectrum? spectrum;

  const FrequencyDetailsCard({super.key, required this.spectrum});

  @override
  Widget build(BuildContext context) {
    final currentSpectrum = spectrum;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: currentSpectrum == null
            ? Center(
                child: Text(
                  AppStrings.noFrequencyData,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppStrings.peakFrequency,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currentSpectrum.peakFrequency.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Hz', style: TextStyle(color: textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        context,
                        AppStrings.avgFrequency,
                        '${currentSpectrum.statistics.avgFrequency.toStringAsFixed(1)} Hz',
                      ),
                      _buildStatColumn(
                        context,
                        '最大パワー',
                        '${currentSpectrum.peakMagnitudeDb.toStringAsFixed(1)} dB',
                      ),
                    ],
                  ),
                  if (currentSpectrum.topFrequencies.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      AppStrings.dominantFrequencies,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentSpectrum.topFrequencies
                          .map((peak) => _buildFrequencyChip(peak))
                          .toList(),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildFrequencyChip(FrequencyPeak peak) {
    return Chip(
      backgroundColor: primaryColor.withOpacity(0.08),
      label: Text(
        '${peak.frequency.toStringAsFixed(0)} Hz',
        style: const TextStyle(color: primaryDark, fontWeight: FontWeight.w600),
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
