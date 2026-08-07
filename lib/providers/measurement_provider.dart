import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/measurement_model.dart';
import '../services/firebase_service.dart';
import '../services/hive_service.dart';
import 'auth_provider.dart';

final measurementServiceProvider = Provider((ref) => FirebaseService());

final measurementsByProjectProvider =
    StreamProvider.family<List<MeasurementModel>, String>((ref, projectId) {
  final currentUser = ref.watch(currentUserProvider);
  final firebaseService = ref.watch(measurementServiceProvider);

  if (currentUser == null) {
    return Stream.value([]);
  }

  return firebaseService.streamMeasurements(currentUser.uid, projectId);
});

class MeasurementNotifier extends StateNotifier<AsyncValue<void>> {
  MeasurementNotifier(
    this._firebaseService,
  ) : super(const AsyncValue.data(null));

  final FirebaseService _firebaseService;

  Future<MeasurementModel> createMeasurement({
    required String userId,
    required String projectId,
    required double dbValue,
    required double dbMin,
    required double dbAvg,
    required double dbMax,
    required int durationMs,
    String? memo,
    double calibrationOffset = 0.0,
    String deviceInfo = '',
    double? peakFrequency,
    List<double>? dominantFrequencies,
  }) async {
    state = const AsyncValue.loading();
    try {
      final measurement = MeasurementModel(
        id: const Uuid().v4(),
        projectId: projectId,
        type: 0,
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
      await _firebaseService.deleteMeasurement(userId, projectId, measurementId);
    });
  }
}

final measurementProvider =
    StateNotifierProvider<MeasurementNotifier, AsyncValue<void>>(
  (ref) => MeasurementNotifier(
    ref.watch(measurementServiceProvider),
  ),
);
