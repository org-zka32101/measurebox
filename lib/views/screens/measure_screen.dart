import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../models/measurement_model.dart';
import '../../services/audio_service.dart';
import '../../services/frequency_analysis_service.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/error_messages.dart';
import '../widgets/decibel_gauge.dart';
import '../widgets/frequency_spectrum_widget.dart';
import '../widgets/frequency_details_card.dart';

class MeasureScreen extends ConsumerStatefulWidget {
  static const String guestUserId = 'guest-user';

  final String projectId;

  const MeasureScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen>
    with SingleTickerProviderStateMixin {
  late AudioService _audioService;
  late TabController _tabController;
  bool _isMeasuring = false;
  double _currentDb = 0.0;
  double _minDb = 0.0;
  double _avgDb = 0.0;
  double _maxDb = 0.0;
  FrequencySpectrum? _currentSpectrum;
  MeasurementModel? _lastMeasurement;

  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _tabController = TabController(length: 2, vsync: this);
    _memoController = TextEditingController();
    _checkMicrophonePermission();
  }

  @override
  void dispose() {
    if (_isMeasuring) {
      _audioService.stopMeasurement();
      _audioService.stopFrequencyMeasurement();
    }
    _tabController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    final hasPermission = await _audioService.hasMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.micPermissionRequired),
            action: SnackBarAction(
              label: '許可',
              onPressed: () async {
                final granted = await _audioService.requestMicrophonePermission();
                if (granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('マイク権限が許可されました')),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }

  void _startMeasuring() async {
    final hasPermission = await _audioService.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _audioService.requestMicrophonePermission();
      if (!granted) return;
    }

    try {
      await _audioService.startMeasurement(
        onDBChange: (db, min, max, avg) {
          setState(() {
            _currentDb = db;
            _minDb = min;
            _maxDb = max;
            _avgDb = avg;
          });
        },
      );
      await _audioService.startFrequencyMeasurement(
        onSpectrumChange: (spectrum) {
          setState(() => _currentSpectrum = spectrum);
        },
      );

      setState(() => _isMeasuring = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _stopMeasuring() async {
    try {
      await _audioService.stopMeasurement();
      await _audioService.stopFrequencyMeasurement();

      final durationMs = DateTime.now().difference(_audioService.getStartTime() ?? DateTime.now()).inMilliseconds;

      final hasFrequencyData = _audioService.getPeakFrequencyHistory().isNotEmpty;

      _lastMeasurement = MeasurementModel(
        id: '',
        projectId: widget.projectId,
        type: 0,
        dbValue: _currentDb,
        dbMin: _minDb,
        dbAvg: _avgDb,
        dbMax: _maxDb,
        durationMs: durationMs,
        timestamp: DateTime.now(),
        memo: null,
        peakFrequency: hasFrequencyData ? _audioService.avgPeakFrequency : null,
        dominantFrequencies: _currentSpectrum?.topFrequencies
            .map((peak) => peak.frequency)
            .toList(),
      );

      setState(() => _isMeasuring = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _saveMeasurement() async {
    if (_lastMeasurement == null) return;

    try {
      // Settings画面で設定したマイク校正オフセットを反映する
      // (createMeasurement内でdbValue/min/avg/maxに加算される)。
      final calibrationOffset = ref.read(calibrationProvider);
      await ref.read(measurementProvider.notifier).createMeasurement(
            userId: MeasureScreen.guestUserId,
            projectId: widget.projectId,
            dbValue: _lastMeasurement!.dbValue,
            dbMin: _lastMeasurement!.dbMin,
            dbAvg: _lastMeasurement!.dbAvg,
            dbMax: _lastMeasurement!.dbMax,
            durationMs: _lastMeasurement!.durationMs,
            memo: _memoController.text.isEmpty ? null : _memoController.text,
            calibrationOffset: calibrationOffset,
            peakFrequency: _lastMeasurement!.peakFrequency,
            dominantFrequencies: _lastMeasurement!.dominantFrequencies,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('測定を保存しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  String _statusLabel(double db) {
    if (db < 70) return AppStrings.safe;
    if (db < 85) return AppStrings.warning;
    return AppStrings.danger;
  }

  Color _statusColor(double db) {
    if (db < 70) return safeColor;
    if (db < 85) return warningColor;
    return dangerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.measure),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: '使い方',
            onPressed: _showGuide,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppStrings.volumeTab),
            Tab(text: AppStrings.frequencyTab),
          ],
        ),
      ),
      body: Column(
        children: [
          // 操作ヒント（測定前のみ）
          if (!_isMeasuring && _lastMeasurement == null)
            Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.measureHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primaryDark,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVolumeTab(context),
                _buildFrequencyTab(context),
              ],
            ),
          ),

          // Control buttons（両タブ共通・1回の測定でdB/周波数を同時記録）
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: _isMeasuring
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _stopMeasuring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerColor,
                      ),
                      child: Text(AppStrings.stopMeasure),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startMeasuring,
                          child: Text(AppStrings.startMeasure),
                        ),
                      ),
                      if (_lastMeasurement != null) ...[
                        const SizedBox(height: 16),
                        // Memo input
                        TextField(
                          controller: _memoController,
                          decoration: InputDecoration(
                            hintText: AppStrings.memo,
                            labelText: AppStrings.memo,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        // Save/Discard buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _lastMeasurement = null;
                                  _currentDb = 0;
                                  _minDb = 0;
                                  _maxDb = 0;
                                  _avgDb = 0;
                                  _currentSpectrum = null;
                                  _memoController.clear();
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[400],
                                ),
                                child: const Text('破棄'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveMeasurement,
                                child: Text(AppStrings.save),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeTab(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Gauge
            DecibelGauge(
              value: _currentDb,
              isAnimating: _isMeasuring,
            ),

            // 現在のステータスバッジ（測定中、および測定停止後の確認中も
            // 表示し続ける。停止直後に安全/注意/危険の文脈が消えると、
            // ユーザーは保存前にdBの数値だけを見て判断することになる）
            if (_isMeasuring || _lastMeasurement != null) ...[
              Builder(builder: (context) {
                final displayDb = _lastMeasurement?.dbValue ?? _currentDb;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(displayDb).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: _statusColor(displayDb)),
                        const SizedBox(width: 8),
                        Text(
                          _statusLabel(displayDb),
                          style: TextStyle(
                            color: _statusColor(displayDb),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('最小', '${_minDb.toStringAsFixed(1)} dB'),
                          _buildStatColumn('平均', '${_avgDb.toStringAsFixed(1)} dB'),
                          _buildStatColumn('最大', '${_maxDb.toStringAsFixed(1)} dB'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyTab(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            FrequencySpectrumWidget(spectrum: _currentSpectrum),
            const SizedBox(height: 16),
            FrequencyDetailsCard(spectrum: _currentSpectrum),
          ],
        ),
      ),
    );
  }

  void _showGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.measureGuideTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _guideRow(safeColor, AppStrings.guideSafe),
            const SizedBox(height: 10),
            _guideRow(warningColor, AppStrings.guideWarning),
            const SizedBox(height: 10),
            _guideRow(dangerColor, AppStrings.guideDanger),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideRow(Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
