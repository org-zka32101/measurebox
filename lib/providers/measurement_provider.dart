import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/measurement_category.dart';
import '../models/measurement_model.dart';
import '../models/measurement_type.dart';
import '../services/firebase_service.dart';
import '../services/guest_auth_service.dart';

final measurementServiceProvider = Provider((ref) => FirebaseService());

final measurementsByProjectProvider =
    StreamProvider.family<List<MeasurementModel>, String>((ref, projectId) {
      final firebaseService = ref.watch(measurementServiceProvider);

      // ゲストモード：匿名認証のuidで直接アクセス（GuestAuthServiceの
      // ドキュメント参照）。起動時のサインインに失敗している場合は
      // （オフライン等）同期を諦め、空リストを返す。
      final guestUserId = GuestAuthService.currentUserId;
      if (guestUserId == null) return Stream.value(const []);
      return firebaseService.streamMeasurements(guestUserId, projectId);
    });

class MeasurementNotifier extends StateNotifier<AsyncValue<void>> {
  MeasurementNotifier(this._firebaseService)
    : super(const AsyncValue.data(null));

  final FirebaseService _firebaseService;

  Future<MeasurementModel> createMeasurement({
    required String userId,
    required String projectId,
    // dB系フィールドはcategoryがsound以外(vibration等)の場合は意味を
    // 持たない。モデル自体は既存のdB専用フィールドをnon-nullableのまま
    // 保っているため（呼び出し側全箇所の変更を避けるため）、その場合は
    // 呼び出し元(MeasureScreen)から 0.0 を渡す規約とする。表示側は
    // measurementCategory を見てから dB / 振動どちらの値を出すか判断する。
    required double dbValue,
    required double dbMin,
    required double dbAvg,
    required double dbMax,
    required int durationMs,
    String? memo,
    MeasurementType type = MeasurementType.single,
    MeasurementCategory category = MeasurementCategory.sound,
    double calibrationOffset = 0.0,
    String deviceInfo = '',
    double? peakFrequency,
    List<double>? dominantFrequencies,
    double? vibrationValue,
    double? vibrationMin,
    double? vibrationAvg,
    double? vibrationMax,
    double? latitude,
    double? longitude,
    int? luxValue,
    int? luxMin,
    double? luxAvg,
    int? luxMax,
  }) async {
    state = const AsyncValue.loading();
    try {
      final measurement = MeasurementModel(
        id: const Uuid().v4(),
        projectId: projectId,
        type: type.index,
        dbValue: dbValue + calibrationOffset,
        dbMin: dbMin + calibrationOffset,
        dbAvg: dbAvg + calibrationOffset,
        dbMax: dbMax + calibrationOffset,
        durationMs: durationMs,
        timestamp: DateTime.now(),
        memo: memo,
        calibrationOffset: calibrationOffset,
        deviceInfo: deviceInfo,
        peakFrequency: peakFrequency,
        dominantFrequencies: dominantFrequencies,
        category: category.index,
        vibrationValue: vibrationValue,
        vibrationMin: vibrationMin,
        vibrationAvg: vibrationAvg,
        vibrationMax: vibrationMax,
        latitude: latitude,
        longitude: longitude,
        luxValue: luxValue,
        luxMin: luxMin,
        luxAvg: luxAvg,
        luxMax: luxMax,
      );
      await _firebaseService.saveMeasurement(userId, projectId, measurement);
      state = const AsyncValue.data(null);
      return measurement;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteMeasurement({
    required String userId,
    required String projectId,
    required String measurementId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firebaseService.deleteMeasurement(
        userId,
        projectId,
        measurementId,
      );
    });
  }
}

final measurementProvider =
    StateNotifierProvider<MeasurementNotifier, AsyncValue<void>>(
      (ref) => MeasurementNotifier(ref.watch(measurementServiceProvider)),
    );
