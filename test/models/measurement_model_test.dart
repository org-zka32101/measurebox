import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/models/measurement_model.dart';

void main() {
  group('MeasurementModel', () {
    test('创建 measurement with correct values', () {
      final measurement = MeasurementModel(
        id: '1',
        projectId: 'proj1',
        type: 0,
        dbValue: 75.0,
        dbMin: 70.0,
        dbAvg: 72.5,
        dbMax: 80.0,
        durationMs: 5000,
        timestamp: DateTime(2026, 6, 14),
        calibrationOffset: 0.0,
        deviceInfo: 'iOS',
      );

      expect(measurement.id, equals('1'));
      expect(measurement.projectId, equals('proj1'));
      expect(measurement.dbValue, equals(75.0));
      expect(measurement.dbMin, equals(70.0));
      expect(measurement.dbAvg, equals(72.5));
      expect(measurement.dbMax, equals(80.0));
      expect(measurement.durationMs, equals(5000));
    });

    test('copyWith updates values correctly', () {
      final original = MeasurementModel(
        id: '1',
        projectId: 'proj1',
        type: 0,
        dbValue: 75.0,
        dbMin: 70.0,
        dbAvg: 72.5,
        dbMax: 80.0,
        durationMs: 5000,
        timestamp: DateTime(2026, 6, 14),
      );

      final updated = original.copyWith(
        dbValue: 78.0,
        memo: 'Test memo',
      );

      expect(updated.dbValue, equals(78.0));
      expect(updated.memo, equals('Test memo'));
      expect(updated.id, equals(original.id));
      expect(updated.projectId, equals(original.projectId));
    });

    test('toFirestore returns correct map', () {
      final measurement = MeasurementModel(
        id: '1',
        projectId: 'proj1',
        type: 0,
        dbValue: 75.0,
        dbMin: 70.0,
        dbAvg: 72.5,
        dbMax: 80.0,
        durationMs: 5000,
        timestamp: DateTime(2026, 6, 14, 10, 30),
      );

      final firestore = measurement.toFirestore();

      expect(firestore['id'], equals('1'));
      expect(firestore['dB_value'], equals(75.0));
      expect(firestore['dB_min'], equals(70.0));
      expect(firestore['dB_avg'], equals(72.5));
      expect(firestore['dB_max'], equals(80.0));
      expect(firestore['duration_ms'], equals(5000));
    });

    test('fromFirestore creates correct model', () {
      final firestoreData = {
        'id': '1',
        'type': 'single',
        'dB_value': 75.0,
        'dB_min': 70.0,
        'dB_avg': 72.5,
        'dB_max': 80.0,
        'duration_ms': 5000,
        'timestamp': DateTime(2026, 6, 14),
        'memo': 'Test',
        'calibration_offset': 1.0,
        'device_info': 'iOS',
      };

      final measurement = MeasurementModel.fromFirestore(firestoreData, 'proj1');

      expect(measurement.id, equals('1'));
      expect(measurement.projectId, equals('proj1'));
      expect(measurement.dbValue, equals(75.0));
      expect(measurement.memo, equals('Test'));
    });
  });
}
