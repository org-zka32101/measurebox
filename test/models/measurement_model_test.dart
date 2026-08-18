import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/models/measurement_category.dart';
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

      final updated = original.copyWith(dbValue: 78.0, memo: 'Test memo');

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

      final measurement = MeasurementModel.fromFirestore(
        firestoreData,
        'proj1',
      );

      expect(measurement.id, equals('1'));
      expect(measurement.projectId, equals('proj1'));
      expect(measurement.dbValue, equals(75.0));
      expect(measurement.memo, equals('Test'));
    });

    test('defaults to sound category when unspecified', () {
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
      );

      expect(measurement.measurementCategory, MeasurementCategory.sound);
    });

    test('toFirestore/fromFirestore round-trips a vibration measurement', () {
      final measurement = MeasurementModel(
        id: '1',
        projectId: 'proj1',
        type: 0,
        dbValue: 0.0,
        dbMin: 0.0,
        dbAvg: 0.0,
        dbMax: 0.0,
        durationMs: 5000,
        timestamp: DateTime(2026, 6, 14, 10, 30),
        category: MeasurementCategory.vibration.index,
        vibrationValue: 3.2,
        vibrationMin: 0.5,
        vibrationAvg: 2.1,
        vibrationMax: 6.4,
      );

      final firestore = measurement.toFirestore();
      expect(firestore['category'], equals('vibration'));
      expect(firestore['vibration_value'], equals(3.2));
      expect(firestore['vibration_min'], equals(0.5));
      expect(firestore['vibration_avg'], equals(2.1));
      expect(firestore['vibration_max'], equals(6.4));

      final restored = MeasurementModel.fromFirestore(firestore, 'proj1');
      expect(restored.measurementCategory, MeasurementCategory.vibration);
      expect(restored.vibrationValue, equals(3.2));
      expect(restored.vibrationMin, equals(0.5));
      expect(restored.vibrationAvg, equals(2.1));
      expect(restored.vibrationMax, equals(6.4));
    });

    test('fromFirestore defaults to sound category for pre-existing documents '
        'with no category key', () {
      final legacyData = {
        'id': '1',
        'type': 'single',
        'dB_value': 75.0,
        'dB_min': 70.0,
        'dB_avg': 72.5,
        'dB_max': 80.0,
        'duration_ms': 5000,
        'timestamp': DateTime(2026, 6, 14),
      };

      final measurement = MeasurementModel.fromFirestore(legacyData, 'proj1');

      expect(measurement.measurementCategory, MeasurementCategory.sound);
      expect(measurement.vibrationValue, isNull);
    });
  });
}
