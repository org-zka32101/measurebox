import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/config.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';

// ゲストモード：他のprovider (project/measurement/comparison) と同じ
// 固定ユーザーIDを使用
const _guestUserId = 'guest-user';

/// マイク校正オフセット (dB) の状態管理。
///
/// これまで SettingsScreen 内のローカル state (`late double _calibration`)
/// だけで管理されており、画面を開くたびに [defaultCalibration] にリセット
/// され、どこにも永続化されず、`MeasureScreen._saveMeasurement` からも
/// 一切参照されていなかった（スライダーを動かしても実際の測定値には
/// 何の影響もない、見た目だけのダミー機能だった）。
///
/// ローカルDB (Hive) の `UserModel.calibration` フィールドに永続化し、
/// アプリ再起動後も設定が保持されるようにする。
class CalibrationNotifier extends StateNotifier<double> {
  CalibrationNotifier() : super(_readPersisted());

  static double _readPersisted() {
    final user = HiveService.getUserBox().get(_guestUserId);
    return user?.calibration ?? defaultCalibration;
  }

  Future<void> setCalibration(double value) async {
    state = value;
    final box = HiveService.getUserBox();
    final existing = box.get(_guestUserId);
    final updated = (existing ??
            UserModel(
              uid: _guestUserId,
              email: '',
              createdAt: DateTime.now(),
            ))
        .copyWith(calibration: value);
    await box.put(_guestUserId, updated);
  }
}

final calibrationProvider =
    StateNotifierProvider<CalibrationNotifier, double>(
  (ref) => CalibrationNotifier(),
);
