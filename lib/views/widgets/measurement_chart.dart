import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/colors.dart';
import '../../models/measurement_model.dart';

class MeasurementChart extends StatelessWidget {
  final MeasurementModel? before;
  final MeasurementModel? after;
  final String? title;

  const MeasurementChart({
    super.key,
    this.before,
    this.after,
    this.title,
  });

  List<BarChartGroupData> _getChartData() {
    final groups = <BarChartGroupData>[];

    if (before != null) {
      groups.add(
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: before!.dbValue,
              color: primaryColor,
              width: 40,
            ),
          ],
        ),
      );
    }

    if (after != null) {
      final afterVal = after!;
      groups.add(
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: afterVal.dbValue,
              color: (before != null && afterVal.dbValue < before!.dbValue)
                  ? safeColor
                  : dangerColor,
              width: 40,
            ),
          ],
        ),
      );
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (before == null && after == null) {
      return Center(
        child: Text(
          '測定データがありません',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: _getChartData(),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (before != null && value == 0) {
                          return const Text('対策前');
                        }
                        if (after != null && value == 1) {
                          return const Text('対策後');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 0.5,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LineComparisonChart extends StatelessWidget {
  final MeasurementModel? before;
  final MeasurementModel? after;

  const LineComparisonChart({
    super.key,
    this.before,
    this.after,
  });

  @override
  Widget build(BuildContext context) {
    if (before == null && after == null) {
      return const SizedBox();
    }

    final spots = <FlSpot>[];
    if (before != null) {
      spots.add(FlSpot(0, before!.dbValue));
      spots.add(FlSpot(0.5, before!.dbAvg));
    }
    if (after != null) {
      spots.add(FlSpot(1, after!.dbValue));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 250,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: index == 1 ? safeColor : primaryColor,
                    strokeWidth: 0,
                  );
                },
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('対策前');
                  if (value == 1) return const Text('対策後');
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
        ),
      ),
    );
  }
}

class TimeSeriesChart extends StatelessWidget {
  final List<MeasurementModel> measurements;
  final String? title;

  const TimeSeriesChart({
    super.key,
    required this.measurements,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Center(
        child: Text(
          '測定データがありません',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < measurements.length; i++) {
      spots.add(FlSpot(i.toDouble(), measurements[i].dbValue));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: primaryColor,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < measurements.length) {
                          final time = measurements[index].timestamp;
                          return Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()} dB', style: const TextStyle(fontSize: 10));
                      },
                      reservedSize: 45,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 0.5,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
