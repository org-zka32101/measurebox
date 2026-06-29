import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/models/comparison_model.dart';

void main() {
  group('ComparisonModel', () {
    test('creates comparison with correct values', () {
      final comparison = ComparisonModel(
        id: '1',
        projectId: 'proj1',
        beforeMeasurementId: 'before1',
        afterMeasurementId: 'after1',
        improvementDb: -4.0,
        improvementRate: -5.6,
        createdAt: DateTime(2026, 6, 14),
      );

      expect(comparison.id, equals('1'));
      expect(comparison.projectId, equals('proj1'));
      expect(comparison.beforeMeasurementId, equals('before1'));
      expect(comparison.afterMeasurementId, equals('after1'));
      expect(comparison.improvementDb, equals(-4.0));
      expect(comparison.improvementRate, equals(-5.6));
    });

    test('copyWith updates values correctly', () {
      final original = ComparisonModel(
        id: '1',
        projectId: 'proj1',
        beforeMeasurementId: 'before1',
        afterMeasurementId: 'after1',
        improvementDb: -4.0,
        improvementRate: -5.6,
        createdAt: DateTime(2026, 6, 14),
      );

      final updated = original.copyWith(
        improvementDb: -5.0,
        memo: 'Updated memo',
      );

      expect(updated.improvementDb, equals(-5.0));
      expect(updated.memo, equals('Updated memo'));
      expect(updated.id, equals(original.id));
      expect(updated.projectId, equals(original.projectId));
    });

    test('toFirestore returns correct map', () {
      final comparison = ComparisonModel(
        id: '1',
        projectId: 'proj1',
        beforeMeasurementId: 'before1',
        afterMeasurementId: 'after1',
        improvementDb: -4.0,
        improvementRate: -5.6,
        createdAt: DateTime(2026, 6, 14, 10, 30),
        memo: 'Test',
      );

      final firestore = comparison.toFirestore();

      expect(firestore['id'], equals('1'));
      expect(firestore['beforeMeasurementId'], equals('before1'));
      expect(firestore['afterMeasurementId'], equals('after1'));
      expect(firestore['improvement_dB'], equals(-4.0));
      expect(firestore['improvement_rate'], equals(-5.6));
      expect(firestore['memo'], equals('Test'));
    });

    test('fromFirestore creates correct model', () {
      final firestoreData = {
        'id': '1',
        'beforeMeasurementId': 'before1',
        'afterMeasurementId': 'after1',
        'improvement_dB': -4.0,
        'improvement_rate': -5.6,
        'createdAt': DateTime(2026, 6, 14),
        'memo': 'Test',
      };

      final comparison = ComparisonModel.fromFirestore(firestoreData, 'proj1');

      expect(comparison.id, equals('1'));
      expect(comparison.projectId, equals('proj1'));
      expect(comparison.improvementDb, equals(-4.0));
      expect(comparison.improvementRate, equals(-5.6));
      expect(comparison.memo, equals('Test'));
    });

    test('improvement calculation (negative = improvement)', () {
      final comparison = ComparisonModel(
        id: '1',
        projectId: 'proj1',
        beforeMeasurementId: 'before1',
        afterMeasurementId: 'after1',
        improvementDb: -4.0, // Negative = noise reduced (good)
        improvementRate: -5.6,
        createdAt: DateTime(2026, 6, 14),
      );

      // Negative improvement = noise was reduced
      expect(comparison.improvementDb, lessThan(0));
    });
  });
}
