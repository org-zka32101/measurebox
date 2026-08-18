import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../models/measurement_model.dart';
import '../../providers/measurement_provider.dart';
import '../../services/csv_service.dart';
import '../../utils/error_messages.dart';
import '../widgets/error_state_view.dart';
import '../widgets/measurement_chart.dart';

class LogsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const LogsScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  Color _getStatusColor(double dbValue) {
    if (dbValue < 70) return safeColor;
    if (dbValue < 85) return warningColor;
    return dangerColor;
  }

  String _getStatusLabel(double dbValue) {
    if (dbValue < 70) return AppStrings.safe;
    if (dbValue < 85) return AppStrings.warning;
    return AppStrings.danger;
  }

  void _showDateRangeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('日付範囲で絞込'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '開始日: ${_filterStartDate != null ? DateFormat('yyyy-MM-dd').format(_filterStartDate!) : '指定なし'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _filterStartDate = date);
                }
              },
              child: const Text('開始日を選択'),
            ),
            const SizedBox(height: 12),
            Text(
              '終了日: ${_filterEndDate != null ? DateFormat('yyyy-MM-dd').format(_filterEndDate!) : '指定なし'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterEndDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _filterEndDate = date);
                }
              },
              child: const Text('終了日を選択'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterStartDate = null;
                _filterEndDate = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('リセット'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  void _exportCSV(BuildContext context, List<MeasurementModel> measurements) async {
    try {
      final csvService = CSVService();
      final csv = await csvService.generateCSV(
        measurements: measurements,
        projectName: 'MeasureBox_${widget.projectId}',
      );
      final file = await csvService.saveCSV(
        csv: csv,
        projectName: 'MeasureBox_${widget.projectId}',
      );

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
    final measurementsAsync = ref.watch(measurementsByProjectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.logs),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showDateRangeFilter,
            tooltip: '日付絞込',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: measurementsAsync.hasValue
                ? () => _exportCSV(context, measurementsAsync.value!)
                : null,
            tooltip: measurementsAsync.hasValue
                ? AppStrings.exportCSV
                : '読み込み中です',
          ),
        ],
      ),
      body: measurementsAsync.when(
        data: (measurements) {
          // Apply date filter
          final filteredMeasurements = measurements.where((m) {
            if (_filterStartDate != null && m.timestamp.isBefore(_filterStartDate!)) return false;
            if (_filterEndDate != null && m.timestamp.isAfter(_filterEndDate!.add(const Duration(days: 1)))) return false;
            return true;
          }).toList();

          // Sort by date
          filteredMeasurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          if (filteredMeasurements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 44,
                      color: warningColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.noLogs,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.logsHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          // Sort by date descending
          final sortedMeasurements = List<MeasurementModel>.from(filteredMeasurements)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return SingleChildScrollView(
            child: Column(
              children: [
                TimeSeriesChart(
                  measurements: filteredMeasurements,
                  title: '測定値の推移',
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedMeasurements.length,
                  itemBuilder: (context, index) {
                    final measurement = sortedMeasurements[index];
                    final statusColor = _getStatusColor(measurement.dbValue);
                    final statusLabel = _getStatusLabel(measurement.dbValue);
                    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${measurement.dbValue.toStringAsFixed(1)} dB',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(color: statusColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatter.format(measurement.timestamp),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    border: Border.all(color: statusColor),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            context,
                            '最小',
                            measurement.dbMin.toStringAsFixed(1),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: greyLight,
                          ),
                          _buildStatItem(
                            context,
                            '平均',
                            measurement.dbAvg.toStringAsFixed(1),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: greyLight,
                          ),
                          _buildStatItem(
                            context,
                            '最大',
                            measurement.dbMax.toStringAsFixed(1),
                          ),
                        ],
                      ),
                      if (measurement.memo != null && measurement.memo!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              measurement.memo!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorStateView(
          error: error,
          onRetry: () =>
              ref.invalidate(measurementsByProjectProvider(widget.projectId)),
        ),
      ),
    );
    });
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
