import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/models/measurement_model.dart';
import 'package:measurebox/services/csv_service.dart';

void main() {
  group('CSVService', () {
    late CSVService csvService;

    setUp(() {
      csvService = CSVService();
    });

    test('generateCSV creates valid CSV format', () async {
      final measurements = [
        MeasurementModel(
          id: '1',
          projectId: 'proj1',
          type: 0,
          dbValue: 75.0,
          dbMin: 70.0,
          dbAvg: 72.5,
          dbMax: 80.0,
          durationMs: 5000,
          timestamp: DateTime(2026, 6, 14, 10, 30),
        ),
        MeasurementModel(
          id: '2',
          projectId: 'proj1',
          type: 0,
          dbValue: 68.0,
          dbMin: 65.0,
          dbAvg: 67.0,
          dbMax: 70.0,
          durationMs: 4000,
          timestamp: DateTime(2026, 6, 14, 11, 0),
          memo: 'Test memo',
        ),
      ];

      final csv = await csvService.generateCSV(
        measurements: measurements,
        projectName: 'TestProject',
      );

      expect(csv, isNotEmpty);
      expect(csv, contains('日時'));
      expect(csv, contains('プロジェクト'));
      expect(csv, contains('dB値'));
      expect(csv, contains('75.0'));
      expect(csv, contains('68.0'));
      expect(csv, contains('Test memo'));
    });

    test('generateCSV handles empty measurements', () async {
      final csv = await csvService.generateCSV(
        measurements: [],
        projectName: 'TestProject',
      );

      expect(csv, isNotEmpty);
      expect(csv, contains('日時'));
    });

    test('generateCSV includes memo field', () async {
      final measurements = [
        MeasurementModel(
          id: '1',
          projectId: 'proj1',
          type: 0,
          dbValue: 75.0,
          dbMin: 70.0,
          dbAvg: 72.5,
          dbMax: 80.0,
          durationMs: 5000,
          timestamp: DateTime(2026, 6, 14),
          memo: 'Test memo with special chars: 日本語, !@#$%',
        ),
      ];

      final csv = await csvService.generateCSV(
        measurements: measurements,
        projectName: 'TestProject',
      );

      expect(csv, contains('Test memo with special chars'));
    });
  });
}
