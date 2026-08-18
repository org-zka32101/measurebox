import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../constants/config.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // スライダー操作中はローカルstateで即座に描画を更新し、指を離した時点
  // (onChangeEnd) でHiveへ永続化する。永続化された値はcalibrationProvider
  // からinitStateで読み込む。
  late double _calibration;

  @override
  void initState() {
    super.initState();
    _calibration = ref.read(calibrationProvider);
  }

  void _handleCalibrationChange(double value) {
    setState(() => _calibration = value);
  }

  Future<void> _handleCalibrationChangeEnd(double value) async {
    await ref.read(calibrationProvider.notifier).setCalibration(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('マイク感度オフセットを ${value.toStringAsFixed(1)} dB に保存しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Guest Mode Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.account,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: safeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: safeColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ゲストモード',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ログイン不要でご利用いただけます',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Calibration Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.calibration,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'マイク感度オフセット',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${_calibration.toStringAsFixed(1)} dB',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _calibration,
                    min: minCalibration,
                    max: maxCalibration,
                    divisions: ((maxCalibration - minCalibration) / calibrationStep).toInt(),
                    onChanged: _handleCalibrationChange,
                    onChangeEnd: _handleCalibrationChangeEnd,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${minCalibration.toInt()} dB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                      Text(
                        '${maxCalibration.toInt()} dB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'マイクの感度を調整します。標準値は 0 dB です。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: warningColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
