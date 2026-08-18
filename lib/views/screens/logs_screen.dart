import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../models/measurement_category.dart';
import '../../models/measurement_model.dart';
import '../../models/measurement_type.dart';
import '../../providers/measurement_provider.dart';
import '../../services/csv_service.dart';
import '../../utils/error_messages.dart';
import '../widgets/error_state_view.dart';
import '../widgets/measurement_chart.dart';

class LogsScreen extends ConsumerStatefulWidget {
  static const String guestUserId = 'guest-user';

  final String projectId;

  const LogsScreen({super.key, required this.projectId});

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

  // measure_screen.dartと同じ目安の閾値（校正された安全基準ではない）。
  Color _getVibrationStatusColor(double magnitude) {
    if (magnitude < 2.0) return safeColor;
    if (magnitude < 5.0) return warningColor;
    return dangerColor;
  }

  String _getVibrationStatusLabel(double magnitude) {
    if (magnitude < 2.0) return AppStrings.safe;
    if (magnitude < 5.0) return AppStrings.warning;
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

  void _exportCSV(
    BuildContext context,
    List<MeasurementModel> measurements,
  ) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<bool> _confirmDeleteMeasurement(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この測定を削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: dangerColor),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // Dismissible.confirmDismiss で呼ばれる。ここで実際に削除まで行い、
  // 成功した場合のみ true を返してスワイプアニメーションを完了させる。
  // 失敗時は false を返し、カードを元の位置に戻す（一覧はFirestoreの
  // ストリームで駆動されているため、楽観的に消してから復活させるより
  // 削除確定後にのみ消える方が挙動が分かりやすい）。
  Future<bool> _handleDeleteMeasurement(
    BuildContext context,
    WidgetRef ref,
    String measurementId,
  ) async {
    final confirmed = await _confirmDeleteMeasurement(context);
    if (!confirmed) return false;

    await ref
        .read(measurementProvider.notifier)
        .deleteMeasurement(
          userId: LogsScreen.guestUserId,
          projectId: widget.projectId,
          measurementId: measurementId,
        );
    if (!context.mounted) return false;

    final result = ref.read(measurementProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('削除に失敗しました。もう一度お試しください。'),
          backgroundColor: dangerColor,
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('測定を削除しました')));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final measurementsAsync = ref.watch(
          measurementsByProjectProvider(widget.projectId),
        );

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
                if (_filterStartDate != null &&
                    m.timestamp.isBefore(_filterStartDate!))
                  return false;
                if (_filterEndDate != null &&
                    m.timestamp.isAfter(
                      _filterEndDate!.add(const Duration(days: 1)),
                    ))
                  return false;
                return true;
              }).toList();

              // Sort by date
              filteredMeasurements.sort(
                (a, b) => a.timestamp.compareTo(b.timestamp),
              );

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
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                );
              }

              // Sort by date descending
              final sortedMeasurements = List<MeasurementModel>.from(
                filteredMeasurements,
              )..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // TimeSeriesChartはdbValueを軸にプロットする作りなので、振動
              // 測定（dbValueは常に0のプレースホルダ）を混ぜると、あたかも
              // 0dBの瞬間があったかのような誤解を招くグラフになってしまう。
              // 騒音測定のみに絞り込む。
              final soundMeasurementsForChart = filteredMeasurements
                  .where(
                    (m) => m.measurementCategory == MeasurementCategory.sound,
                  )
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    if (soundMeasurementsForChart.isNotEmpty)
                      TimeSeriesChart(
                        measurements: soundMeasurementsForChart,
                        title: '測定値の推移',
                      ),
                    const SizedBox(height: 16),
                    // スワイプ削除はジェスチャーだけでは気づかれにくいため、
                    // 一覧の上に一言添えておく
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swipe_left_alt_rounded,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '左にスワイプして削除できます',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedMeasurements.length,
                      itemBuilder: (context, index) {
                        final measurement = sortedMeasurements[index];
                        final category = measurement.measurementCategory;
                        final showCategoryBadge =
                            category != MeasurementCategory.sound;
                        // 騒音(dB)・振動(m/s²)・照度(lux)は単位も表示方法も
                        // 異なるため、categoryに応じて出し分ける。照度は
                        // 「多いほど悪い」という前提が成り立たない指標
                        // （用途次第で適正値が変わる）ため、safe/warning/
                        // dangerのような判定バッジは付けない
                        // （statusColor/statusLabelがnullのまま = バッジ非表示）。
                        final double displayValue;
                        final double minValue;
                        final double avgValue;
                        final double maxValue;
                        final String unit;
                        final int decimals;
                        Color? statusColor;
                        String? statusLabel;
                        switch (category) {
                          case MeasurementCategory.vibration:
                            displayValue = measurement.vibrationValue ?? 0.0;
                            minValue = measurement.vibrationMin ?? 0.0;
                            avgValue = measurement.vibrationAvg ?? 0.0;
                            maxValue = measurement.vibrationMax ?? 0.0;
                            unit = 'm/s²';
                            decimals = 2;
                            statusColor = _getVibrationStatusColor(
                              displayValue,
                            );
                            statusLabel = _getVibrationStatusLabel(
                              displayValue,
                            );
                          case MeasurementCategory.illuminance:
                            displayValue = (measurement.luxValue ?? 0)
                                .toDouble();
                            minValue = (measurement.luxMin ?? 0).toDouble();
                            avgValue = measurement.luxAvg ?? 0.0;
                            maxValue = (measurement.luxMax ?? 0).toDouble();
                            unit = 'lux';
                            decimals = 0;
                          case MeasurementCategory.sound:
                            displayValue = measurement.dbValue;
                            minValue = measurement.dbMin;
                            avgValue = measurement.dbAvg;
                            maxValue = measurement.dbMax;
                            unit = 'dB';
                            decimals = 1;
                            statusColor = _getStatusColor(displayValue);
                            statusLabel = _getStatusLabel(displayValue);
                        }
                        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

                        return Dismissible(
                          key: ValueKey(measurement.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: dangerColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) => _handleDeleteMeasurement(
                            context,
                            ref,
                            measurement.id,
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${displayValue.toStringAsFixed(decimals)} $unit',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(color: statusColor),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formatter.format(
                                              measurement.timestamp,
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          if (showCategoryBadge ||
                                              measurement.measurementType !=
                                                  MeasurementType.single) ...[
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                if (showCategoryBadge)
                                                  _categoryBadge(
                                                    category.label,
                                                  ),
                                                if (measurement
                                                        .measurementType !=
                                                    MeasurementType.single)
                                                  _categoryBadge(
                                                    measurement
                                                        .measurementType
                                                        .label,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (statusColor != null &&
                                          statusLabel != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            border: Border.all(
                                              color: statusColor,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatItem(
                                        context,
                                        '最小',
                                        minValue.toStringAsFixed(decimals),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: greyLight,
                                      ),
                                      _buildStatItem(
                                        context,
                                        '平均',
                                        avgValue.toStringAsFixed(decimals),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: greyLight,
                                      ),
                                      _buildStatItem(
                                        context,
                                        '最大',
                                        maxValue.toStringAsFixed(decimals),
                                      ),
                                    ],
                                  ),
                                  if (measurement.memo != null &&
                                      measurement.memo!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          measurement.memo!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ),
                                  if (measurement.hasLocation)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${measurement.latitude!.toStringAsFixed(5)}, '
                                            '${measurement.longitude!.toStringAsFixed(5)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ErrorStateView(
              error: error,
              onRetry: () => ref.invalidate(
                measurementsByProjectProvider(widget.projectId),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
