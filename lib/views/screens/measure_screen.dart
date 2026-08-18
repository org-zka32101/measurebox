import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../models/measurement_category.dart';
import '../../models/measurement_model.dart';
import '../../models/measurement_type.dart';
import '../../services/audio_service.dart';
import '../../services/frequency_analysis_service.dart';
import '../../services/illuminance_service.dart';
import '../../services/location_service.dart';
import '../../services/vibration_service.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/error_messages.dart';
import '../widgets/decibel_gauge.dart';
import '../widgets/frequency_spectrum_widget.dart';
import '../widgets/frequency_details_card.dart';

class MeasureScreen extends ConsumerStatefulWidget {
  static const String guestUserId = 'guest-user';

  final String projectId;

  const MeasureScreen({super.key, required this.projectId});

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen>
    with SingleTickerProviderStateMixin {
  late AudioService _audioService;
  late VibrationService _vibrationService;
  late IlluminanceService _illuminanceService;
  late TabController _tabController;
  bool _isMeasuring = false;
  double _currentDb = 0.0;
  double _minDb = 0.0;
  double _avgDb = 0.0;
  double _maxDb = 0.0;
  FrequencySpectrum? _currentSpectrum;

  // 振動タブ（音量/周波数とは独立した測定モード。加速度センサーから
  // 実データを取得する — VibrationServiceのドキュメント参照）
  double _currentVibration = 0.0;
  double _minVibration = 0.0;
  double _avgVibration = 0.0;
  double _maxVibration = 0.0;

  // 照度タブ — Android専用（IlluminanceServiceのドキュメント参照）。
  // iOSでは _showIlluminanceTab が false になり、タブ自体を表示しない。
  late final bool _showIlluminanceTab;
  // null=判定中、true=利用可能、false=この端末には照度センサーが無い。
  bool? _illuminanceAvailable;
  int _currentLux = 0;
  int _minLux = 0;
  double _avgLux = 0.0;
  int _maxLux = 0;

  MeasurementModel? _lastMeasurement;

  // 音量/周波数タブはAudioServiceによる1回の録音セッションから両方の
  // データを同時取得する既存の挙動を維持しつつ、振動・照度はそれぞれ
  // 完全に別の測定モードとして扱う（1件の測定は必ずいずれか一方の
  // categoryになるため）。
  bool get _isVibrationTab => _tabController.index == 2;
  bool get _isIlluminanceTab =>
      _showIlluminanceTab && _tabController.index == 3;

  // 対策前後比較の対象として記録するかどうかのタグ付け。既存の
  // MeasurementType (単発/対策前/対策後) はモデル・Firestore保存では
  // 元々対応済みだったが、実際に値を設定する画面側の導線が無く、
  // 常に単発固定で保存されていた。ここで選択→保存まで繋ぐ。
  MeasurementType _selectedType = MeasurementType.single;

  // 位置情報タグ付け（任意・既定はオフ）。オンの場合のみ保存時に一度だけ
  // 現在地を取得する（測定中に継続的に位置を追跡することはしない）。
  final LocationService _locationService = LocationService();
  bool _tagLocation = false;
  bool _isFetchingLocation = false;

  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _vibrationService = VibrationService();
    _illuminanceService = IlluminanceService();
    _showIlluminanceTab = Platform.isAndroid;
    _tabController = TabController(
      length: _showIlluminanceTab ? 4 : 3,
      vsync: this,
    );
    _memoController = TextEditingController();
    _checkMicrophonePermission();
    if (_showIlluminanceTab) {
      IlluminanceService.isAvailable().then((available) {
        if (mounted) setState(() => _illuminanceAvailable = available);
      });
    }
  }

  @override
  void dispose() {
    if (_isMeasuring) {
      _audioService.stopMeasurement();
      _audioService.stopFrequencyMeasurement();
      _vibrationService.stopMeasurement();
      _illuminanceService.stopMeasurement();
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
                final granted = await _audioService
                    .requestMicrophonePermission();
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
    if (_isIlluminanceTab) {
      if (_illuminanceAvailable != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('この端末には照度センサーがありません')));
        return;
      }
      try {
        await _illuminanceService.startMeasurement(
          onLuxChange: (current, min, max, avg) {
            setState(() {
              _currentLux = current;
              _minLux = min;
              _maxLux = max;
              _avgLux = avg;
            });
          },
          onError: (error) {
            if (mounted) {
              setState(() => _isMeasuring = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(friendlyErrorMessage(error))),
              );
            }
          },
        );
        setState(() => _isMeasuring = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
      }
      return;
    }

    if (_isVibrationTab) {
      // 加速度センサーはマイクと違いOSの実行時権限が不要（VibrationService
      // のドキュメント参照）なので権限チェックは行わない。
      try {
        await _vibrationService.startMeasurement(
          onMagnitudeChange: (current, min, max, avg) {
            setState(() {
              _currentVibration = current;
              _minVibration = min;
              _maxVibration = max;
              _avgVibration = avg;
            });
          },
          onError: (error) {
            // 加速度センサーが無い端末（一部の低スペック/古いAndroid機種等）
            // では計測が無音でハングするのを避け、ユーザーに知らせて
            // 測定中状態を解除する。
            if (mounted) {
              setState(() => _isMeasuring = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(friendlyErrorMessage(error))),
              );
            }
          },
        );
        setState(() => _isMeasuring = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
      }
      return;
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _stopMeasuring() async {
    if (_isIlluminanceTab) {
      try {
        final durationMs = DateTime.now()
            .difference(_illuminanceService.startTime ?? DateTime.now())
            .inMilliseconds;

        await _illuminanceService.stopMeasurement();

        _lastMeasurement = MeasurementModel(
          id: '',
          projectId: widget.projectId,
          type: 0,
          category: MeasurementCategory.illuminance.index,
          // dB系フィールドはこのカテゴリでは使わないプレースホルダ
          // （measurement_provider.dart参照）。
          dbValue: 0.0,
          dbMin: 0.0,
          dbAvg: 0.0,
          dbMax: 0.0,
          durationMs: durationMs,
          timestamp: DateTime.now(),
          memo: null,
          luxValue: _currentLux,
          luxMin: _minLux,
          luxAvg: _avgLux,
          luxMax: _maxLux,
        );

        setState(() => _isMeasuring = false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
      }
      return;
    }

    if (_isVibrationTab) {
      try {
        final durationMs = DateTime.now()
            .difference(_vibrationService.startTime ?? DateTime.now())
            .inMilliseconds;

        await _vibrationService.stopMeasurement();

        _lastMeasurement = MeasurementModel(
          id: '',
          projectId: widget.projectId,
          type: 0,
          category: MeasurementCategory.vibration.index,
          // dB系フィールドはこのカテゴリでは使わないプレースホルダ
          // （measurement_provider.dart参照）。
          dbValue: 0.0,
          dbMin: 0.0,
          dbAvg: 0.0,
          dbMax: 0.0,
          durationMs: durationMs,
          timestamp: DateTime.now(),
          memo: null,
          vibrationValue: _currentVibration,
          vibrationMin: _minVibration,
          vibrationAvg: _avgVibration,
          vibrationMax: _maxVibration,
        );

        setState(() => _isMeasuring = false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
      }
      return;
    }

    try {
      await _audioService.stopMeasurement();
      await _audioService.stopFrequencyMeasurement();

      final durationMs = DateTime.now()
          .difference(_audioService.getStartTime() ?? DateTime.now())
          .inMilliseconds;

      final hasFrequencyData = _audioService
          .getPeakFrequencyHistory()
          .isNotEmpty;

      _lastMeasurement = MeasurementModel(
        id: '',
        projectId: widget.projectId,
        type: 0,
        category: MeasurementCategory.sound.index,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _saveMeasurement() async {
    if (_lastMeasurement == null) return;

    final isSound =
        _lastMeasurement!.measurementCategory == MeasurementCategory.sound;

    double? latitude;
    double? longitude;
    if (_tagLocation) {
      // 位置情報の取得に失敗した場合は保存自体を中断する。オフにして
      // 再試行するか、位置情報の許可設定を直してもらう必要があるため、
      // 位置情報無しでこっそり保存するより、失敗を明示する方が分かりやすい。
      setState(() => _isFetchingLocation = true);
      try {
        final location = await _locationService.getCurrentLocation();
        latitude = location.latitude;
        longitude = location.longitude;
      } catch (e) {
        if (mounted) {
          setState(() => _isFetchingLocation = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
        return;
      }
      if (mounted) setState(() => _isFetchingLocation = false);
    }

    try {
      // Settings画面で設定したマイク校正オフセットはdB測定にのみ意味を持つ
      // (createMeasurement内でdbValue/min/avg/maxに加算される)。
      // 振動・照度測定では常に0とする。
      final calibrationOffset = isSound ? ref.read(calibrationProvider) : 0.0;
      await ref
          .read(measurementProvider.notifier)
          .createMeasurement(
            userId: MeasureScreen.guestUserId,
            projectId: widget.projectId,
            category: _lastMeasurement!.measurementCategory,
            dbValue: _lastMeasurement!.dbValue,
            dbMin: _lastMeasurement!.dbMin,
            dbAvg: _lastMeasurement!.dbAvg,
            dbMax: _lastMeasurement!.dbMax,
            durationMs: _lastMeasurement!.durationMs,
            memo: _memoController.text.isEmpty ? null : _memoController.text,
            type: _selectedType,
            calibrationOffset: calibrationOffset,
            peakFrequency: _lastMeasurement!.peakFrequency,
            dominantFrequencies: _lastMeasurement!.dominantFrequencies,
            vibrationValue: _lastMeasurement!.vibrationValue,
            vibrationMin: _lastMeasurement!.vibrationMin,
            vibrationAvg: _lastMeasurement!.vibrationAvg,
            vibrationMax: _lastMeasurement!.vibrationMax,
            latitude: latitude,
            longitude: longitude,
            luxValue: _lastMeasurement!.luxValue,
            luxMin: _lastMeasurement!.luxMin,
            luxAvg: _lastMeasurement!.luxAvg,
            luxMax: _lastMeasurement!.luxMax,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('測定を保存しました')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          // 測定中、および測定後の保存前レビュー中はタブ切り替えを禁止する。
          // 音量/周波数と振動は別々のサービス(AudioService/VibrationService)
          // を裏で動かしており、1件の保存は必ずどちらか一方のcategoryに
          // なるため、録音中や保存前にタブを切り替えると「今どちらを
          // 測定・保存しようとしているか」が分からなくなってしまう。
          child: AbsorbPointer(
            absorbing: _isMeasuring || _lastMeasurement != null,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: AppStrings.volumeTab),
                Tab(text: AppStrings.frequencyTab),
                Tab(text: AppStrings.vibrationTab),
                if (_showIlluminanceTab) Tab(text: AppStrings.illuminanceTab),
              ],
            ),
          ),
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
                  const Icon(
                    Icons.info_outline_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
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
                _buildVibrationTab(context),
                if (_showIlluminanceTab) _buildIlluminanceTab(context),
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
                        // 対策前後比較用のタグ付け（任意・既定は単発）
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '測定の種類',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<MeasurementType>(
                          segments: const [
                            ButtonSegment(
                              value: MeasurementType.single,
                              label: Text('単発'),
                            ),
                            ButtonSegment(
                              value: MeasurementType.before,
                              label: Text('対策前'),
                            ),
                            ButtonSegment(
                              value: MeasurementType.after,
                              label: Text('対策後'),
                            ),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (selection) {
                            setState(() => _selectedType = selection.first);
                          },
                        ),
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
                        const SizedBox(height: 8),
                        // 位置情報タグ付け（任意）。オンにすると保存時に
                        // 一度だけ現在地を取得して測定に紐づける。
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: _tagLocation,
                          onChanged: _isFetchingLocation
                              ? null
                              : (value) => setState(() => _tagLocation = value),
                          secondary: const Icon(Icons.location_on_outlined),
                          title: const Text('位置情報を記録する'),
                          subtitle: const Text('保存時に現在地を取得します'),
                        ),
                        const SizedBox(height: 8),
                        // Save/Discard buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isFetchingLocation
                                    ? null
                                    : () {
                                        _lastMeasurement = null;
                                        _currentDb = 0;
                                        _minDb = 0;
                                        _maxDb = 0;
                                        _avgDb = 0;
                                        _currentSpectrum = null;
                                        _currentVibration = 0;
                                        _minVibration = 0;
                                        _avgVibration = 0;
                                        _maxVibration = 0;
                                        _currentLux = 0;
                                        _minLux = 0;
                                        _avgLux = 0;
                                        _maxLux = 0;
                                        _memoController.clear();
                                        _selectedType = MeasurementType.single;
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
                                onPressed: _isFetchingLocation
                                    ? null
                                    : _saveMeasurement,
                                child: _isFetchingLocation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(AppStrings.save),
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
            DecibelGauge(value: _currentDb, isAnimating: _isMeasuring),

            // 現在のステータスバッジ（測定中、および測定停止後の確認中も
            // 表示し続ける。停止直後に安全/注意/危険の文脈が消えると、
            // ユーザーは保存前にdBの数値だけを見て判断することになる）
            if (_isMeasuring || _lastMeasurement != null) ...[
              Builder(
                builder: (context) {
                  final displayDb = _lastMeasurement?.dbValue ?? _currentDb;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(displayDb).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: _statusColor(displayDb),
                          ),
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
                },
              ),
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
                          _buildStatColumn(
                            '最小',
                            '${_minDb.toStringAsFixed(1)} dB',
                          ),
                          _buildStatColumn(
                            '平均',
                            '${_avgDb.toStringAsFixed(1)} dB',
                          ),
                          _buildStatColumn(
                            '最大',
                            '${_maxDb.toStringAsFixed(1)} dB',
                          ),
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

  // 音量タブの安全/注意/危険のような公的な騒音基準(dB)は無いため、あくまで
  // 目安の閾値。加速度センサーの生の揺れの大きさ(m/s²、重力除去済み)を
  // 大まかに色分けするだけで、振動計測の校正された安全基準ではない点に注意。
  String _vibrationStatusLabel(double magnitude) {
    if (magnitude < 2.0) return AppStrings.safe;
    if (magnitude < 5.0) return AppStrings.warning;
    return AppStrings.danger;
  }

  Color _vibrationStatusColor(double magnitude) {
    if (magnitude < 2.0) return safeColor;
    if (magnitude < 5.0) return warningColor;
    return dangerColor;
  }

  Widget _buildVibrationTab(BuildContext context) {
    final displayMagnitude = _isMeasuring
        ? _currentVibration
        : (_lastMeasurement?.vibrationValue ?? 0.0);
    final statusColor = _vibrationStatusColor(displayMagnitude);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayMagnitude.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'm/s²',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
            if (_isMeasuring || _lastMeasurement != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      _vibrationStatusLabel(displayMagnitude),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        '最小',
                        '${(_isMeasuring ? _minVibration : _lastMeasurement?.vibrationMin ?? 0.0).toStringAsFixed(2)} m/s²',
                      ),
                      _buildStatColumn(
                        '平均',
                        '${(_isMeasuring ? _avgVibration : _lastMeasurement?.vibrationAvg ?? 0.0).toStringAsFixed(2)} m/s²',
                      ),
                      _buildStatColumn(
                        '最大',
                        '${(_isMeasuring ? _maxVibration : _lastMeasurement?.vibrationMax ?? 0.0).toStringAsFixed(2)} m/s²',
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

  // 照度は「多いほど悪い」dB/振動と違い、暗すぎる/明るすぎるのどちらが
  // 問題かは用途次第（JIS等の作業環境照度基準はあるが、対象作業や業種に
  // よって適正値が大きく異なる）。そのため安全/注意/危険のような一律の
  // 判定バッジは付けず、実測値をそのまま提示するに留める。
  Widget _buildIlluminanceTab(BuildContext context) {
    if (_illuminanceAvailable == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_illuminanceAvailable == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.light_mode_outlined,
                size: 44,
                color: textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'この端末には照度センサーがありません',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final displayLux = _isMeasuring
        ? _currentLux
        : (_lastMeasurement?.luxValue ?? 0);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayLux',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'lux',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        '最小',
                        '${_isMeasuring ? _minLux : _lastMeasurement?.luxMin ?? 0} lux',
                      ),
                      _buildStatColumn(
                        '平均',
                        '${(_isMeasuring ? _avgLux : _lastMeasurement?.luxAvg ?? 0.0).toStringAsFixed(0)} lux',
                      ),
                      _buildStatColumn(
                        '最大',
                        '${_isMeasuring ? _maxLux : _lastMeasurement?.luxMax ?? 0} lux',
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
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
