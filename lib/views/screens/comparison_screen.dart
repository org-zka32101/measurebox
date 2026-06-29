import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../models/measurement_model.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/comparison_provider.dart';
import '../widgets/measurement_chart.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  static const String guestUserId = 'guest-user';

  final String projectId;
  final String? initialBeforeMeasurementId;

  const ComparisonScreen({
    super.key,
    required this.projectId,
    this.initialBeforeMeasurementId,
  });

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  String? _selectedBeforeId;
  String? _selectedAfterId;
  MeasurementModel? _beforeMeasurement;
  MeasurementModel? _afterMeasurement;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _selectedBeforeId = widget.initialBeforeMeasurementId;
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
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

  Future<void> _saveComparison() async {
    if (_beforeMeasurement == null || _afterMeasurement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('対策前と対策後の両方を選択してください')),
      );
      return;
    }

    try {
      await ref.read(comparisonProvider.notifier).createComparison(
            userId: ComparisonScreen.guestUserId,
            projectId: widget.projectId,
            beforeMeasurement: _beforeMeasurement!,
            afterMeasurement: _afterMeasurement!,
            memo: _memoController.text.isEmpty ? null : _memoController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('比較を保存しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(measurementsByProjectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.comparison),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showDateRangeFilter,
            tooltip: '日付絞込',
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

          // Update before/after measurements when selected IDs change
          if (_selectedBeforeId != null) {
            try {
              _beforeMeasurement = filteredMeasurements.firstWhere(
                (m) => m.id == _selectedBeforeId,
              );
            } catch (e) {
              _beforeMeasurement = null;
            }
          }
          if (_selectedAfterId != null) {
            try {
              _afterMeasurement = filteredMeasurements.firstWhere(
                (m) => m.id == _selectedAfterId,
              );
            } catch (e) {
              _afterMeasurement = null;
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // 操作ヒント
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: safeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          color: safeColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.comparisonHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Before Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.before,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_beforeMeasurement != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_beforeMeasurement!.dbValue.toStringAsFixed(1)} dB',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(_beforeMeasurement!.timestamp),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('未選択'),
                        ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedBeforeId,
                        hint: const Text('対策前の測定を選択'),
                        items: filteredMeasurements.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(
                              '${m.dbValue.toStringAsFixed(1)} dB - ${DateFormat('MM-dd HH:mm').format(m.timestamp)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBeforeId = value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // After Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.after,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_afterMeasurement != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_afterMeasurement!.dbValue.toStringAsFixed(1)} dB',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(_afterMeasurement!.timestamp),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('未選択'),
                        ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedAfterId,
                        hint: const Text('対策後の測定を選択'),
                        items: filteredMeasurements.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(
                              '${m.dbValue.toStringAsFixed(1)} dB - ${DateFormat('MM-dd HH:mm').format(m.timestamp)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedAfterId = value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Improvement Stats
                if (_beforeMeasurement != null && _afterMeasurement != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: (_afterMeasurement!.dbValue <
                              _beforeMeasurement!.dbValue)
                          ? safeColor.withOpacity(0.1)
                          : dangerColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '改善値',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_beforeMeasurement!.dbValue - _afterMeasurement!.dbValue).toStringAsFixed(1)} dB',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                color: _afterMeasurement!.dbValue <
                                        _beforeMeasurement!.dbValue
                                    ? safeColor
                                    : dangerColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '改善率: ${((_beforeMeasurement!.dbValue - _afterMeasurement!.dbValue) / _beforeMeasurement!.dbValue * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Chart
                if (_beforeMeasurement != null || _afterMeasurement != null)
                  MeasurementChart(
                    before: _beforeMeasurement,
                    after: _afterMeasurement,
                    title: 'Before/After比較',
                  ),

                const SizedBox(height: 24),

                // Memo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _memoController,
                    decoration: InputDecoration(
                      hintText: AppStrings.memo,
                      labelText: AppStrings.memo,
                    ),
                    maxLines: 2,
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveComparison,
                          child: Text(AppStrings.saveComparison),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('キャンセル'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}
