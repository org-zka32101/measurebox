import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/measurement_model.dart';
import '../constants/config.dart';

class CSVService {
  Future<String> generateCSV({
    required List<MeasurementModel> measurements,
    required String projectName,
  }) async {
    // Prepare headers
    final List<List<String>> rows = [
      ['日時', 'プロジェクト', 'dB値', '最小', '平均', '最大', '測定時間(秒)', 'メモ'],
    ];

    // Add data rows
    final dateFormatter = DateFormat(csvDateFormat);
    for (final measurement in measurements) {
      rows.add([
        dateFormatter.format(measurement.timestamp),
        projectName,
        measurement.dbValue.toStringAsFixed(1),
        measurement.dbMin.toStringAsFixed(1),
        measurement.dbAvg.toStringAsFixed(1),
        measurement.dbMax.toStringAsFixed(1),
        (measurement.durationMs / 1000).toStringAsFixed(1),
        measurement.memo ?? '',
      ]);
    }

    // Convert to CSV
    final csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  Future<File> saveCSV({
    required String csv,
    required String projectName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${projectName}_測定ログ_$timestamp.csv';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(csv, encoding: utf8);
    return file;
  }

  Future<String> exportMeasurements({
    required List<MeasurementModel> measurements,
    required String projectName,
  }) async {
    final csv = await generateCSV(
      measurements: measurements,
      projectName: projectName,
    );
    final file = await saveCSV(csv: csv, projectName: projectName);
    return file.path;
  }
}
