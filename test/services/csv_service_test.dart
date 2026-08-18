import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/models/measurement_category.dart';
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
          memo: r'Test memo with special chars: 日本語, !@#$%',
        ),
      ];

      final csv = await csvService.generateCSV(
        measurements: measurements,
        projectName: 'TestProject',
      );

      expect(csv, contains('Test memo with special chars'));
    });

    test(
      'generateCSV keeps sound and vibration values in separate columns',
      () async {
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
            dbValue: 0.0,
            dbMin: 0.0,
            dbAvg: 0.0,
            dbMax: 0.0,
            durationMs: 3000,
            timestamp: DateTime(2026, 6, 14, 11, 0),
            category: MeasurementCategory.vibration.index,
            vibrationValue: 3.2,
            vibrationMin: 0.5,
            vibrationAvg: 2.1,
            vibrationMax: 6.4,
          ),
        ];

        final csv = await csvService.generateCSV(
          measurements: measurements,
          projectName: 'TestProject',
        );

        final rows = csv.split('\n');
        // header + 2 data rows
        expect(rows.length, greaterThanOrEqualTo(3));
        expect(rows[0], contains('種別'));
        expect(rows[0], contains('振動値'));

        // sound row: dB columns filled, vibration columns blank
        expect(rows[1], contains('騒音'));
        expect(rows[1], contains('75.0'));

        // vibration row: vibration columns filled, its own dB placeholder
        // (0.0) is NOT written as a misleading real dB reading
        expect(rows[2], contains('振動'));
        expect(rows[2], contains('3.20'));
        expect(rows[2], isNot(contains('0.0,0.0,0.0,0.0')));
      },
    );

    test('generateCSV writes latitude/longitude when tagged', () async {
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
          latitude: 35.681236,
          longitude: 139.767125,
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
        ),
      ];

      final csv = await csvService.generateCSV(
        measurements: measurements,
        projectName: 'TestProject',
      );

      final rows = csv.split('\n');
      expect(rows[0], contains('緯度'));
      expect(rows[0], contains('経度'));
      expect(rows[1], contains('35.681236'));
      expect(rows[1], contains('139.767125'));
    });

    test('generateCSV keeps illuminance values in their own columns', () async {
      final measurements = [
        MeasurementModel(
          id: '1',
          projectId: 'proj1',
          type: 0,
          dbValue: 0.0,
          dbMin: 0.0,
          dbAvg: 0.0,
          dbMax: 0.0,
          durationMs: 3000,
          timestamp: DateTime(2026, 6, 14, 11, 0),
          category: MeasurementCategory.illuminance.index,
          luxValue: 320,
          luxMin: 280,
          luxAvg: 305.5,
          luxMax: 340,
        ),
      ];

      final csv = await csvService.generateCSV(
        measurements: measurements,
        projectName: 'TestProject',
      );

      final rows = csv.split('\n');
      expect(rows[0], contains('照度値'));
      expect(rows[1], contains('照度'));
      expect(rows[1], contains('320'));
      // dB placeholder (0.0) is not written as a misleading real reading
      expect(rows[1], isNot(contains('0.0,0.0,0.0,0.0')));
    });
  });
}
