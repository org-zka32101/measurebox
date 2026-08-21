import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/comparison_model.dart';
import '../models/measurement_model.dart';
import '../services/firebase_service.dart';
import '../services/guest_auth_service.dart';

final comparisonServiceProvider = Provider((ref) => FirebaseService());

final comparisonsByProjectProvider =
    StreamProvider.family<List<ComparisonModel>, String>((ref, projectId) {
  final firebaseService = ref.watch(comparisonServiceProvider);

  // ゲストモード：匿名認証のuidで直接アクセス（GuestAuthServiceの
  // ドキュメント参照）。起動時のサインインに失敗している場合は
  // （オフライン等）同期を諦め、空リストを返す。
  final guestUserId = GuestAuthService.currentUserId;
  if (guestUserId == null) return Stream.value(const []);
  return firebaseService.streamComparisons(guestUserId, projectId);
});

class ComparisonNotifier extends StateNotifier<AsyncValue<void>> {
  ComparisonNotifier(
    this._firebaseService,
  ) : super(const AsyncValue.data(null));

  final FirebaseService _firebaseService;

  Future<ComparisonModel> createComparison({
    required String userId,
    required String projectId,
    required MeasurementModel beforeMeasurement,
    required MeasurementModel afterMeasurement,
    String? memo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final improvementDb = afterMeasurement.dbValue - beforeMeasurement.dbValue;
      final improvementRate = beforeMeasurement.dbValue != 0
          ? (improvementDb / beforeMeasurement.dbValue) * 100
          : 0.0;

      final comparison = ComparisonModel(
        id: const Uuid().v4(),
        projectId: projectId,
        beforeMeasurementId: beforeMeasurement.id,
        afterMeasurementId: afterMeasurement.id,
        improvementDb: improvementDb,
        improvementRate: improvementRate,
        createdAt: DateTime.now(),
        memo: memo,
      );

      await _firebaseService.saveComparison(userId, projectId, comparison);
      state = const AsyncValue.data(null);
      return comparison;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteComparison({
    required String userId,
    required String projectId,
    required String comparisonId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firebaseService.deleteComparison(userId, projectId, comparisonId);
    });
  }
}

final comparisonProvider =
    StateNotifierProvider<ComparisonNotifier, AsyncValue<void>>(
  (ref) => ComparisonNotifier(
    ref.watch(comparisonServiceProvider),
  ),
);
