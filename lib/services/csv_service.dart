import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/measurement_category.dart';
import '../models/measurement_model.dart';
import '../constants/config.dart';

class CSVService {
  Future<String> generateCSV({
    required List<MeasurementModel> measurements,
    required String projectName,
  }) async {
    // Prepare headers.
    // 種別・振動・照度列を追加: dB/振動/照度の各列はそれぞれのカテゴリの
    // 測定にのみ値が入る（他のカテゴリでは空欄）。1つのCSVで全カテゴリを
    // 扱えるようにするため、列を分けて空欄にする方式を採用（値を混在
    // させない）。
    final List<List<String>> rows = [
      [
        '日時',
        'プロジェクト',
        '種別',
        'dB値',
        'dB最小',
        'dB平均',
        'dB最大',
        '振動値(m/s²)',
        '振動最小(m/s²)',
        '振動平均(m/s²)',
        '振動最大(m/s²)',
        '照度値(lux)',
        '照度最小(lux)',
        '照度平均(lux)',
        '照度最大(lux)',
        '緯度',
        '経度',
        '測定時間(秒)',
        'メモ',
      ],
    ];

    // Add data rows
    final dateFormatter = DateFormat(csvDateFormat);
    for (final measurement in measurements) {
      final category = measurement.measurementCategory;
      final isVibration = category == MeasurementCategory.vibration;
      final isIlluminance = category == MeasurementCategory.illuminance;
      rows.add([
        dateFormatter.format(measurement.timestamp),
        projectName,
        category.label,
        isVibration || isIlluminance
            ? ''
            : measurement.dbValue.toStringAsFixed(1),
        isVibration || isIlluminance
            ? ''
            : measurement.dbMin.toStringAsFixed(1),
        isVibration || isIlluminance
            ? ''
            : measurement.dbAvg.toStringAsFixed(1),
        isVibration || isIlluminance
            ? ''
            : measurement.dbMax.toStringAsFixed(1),
        isVibration
            ? (measurement.vibrationValue ?? 0.0).toStringAsFixed(2)
            : '',
        isVibration ? (measurement.vibrationMin ?? 0.0).toStringAsFixed(2) : '',
        isVibration ? (measurement.vibrationAvg ?? 0.0).toStringAsFixed(2) : '',
        isVibration ? (measurement.vibrationMax ?? 0.0).toStringAsFixed(2) : '',
        isIlluminance ? '${measurement.luxValue ?? 0}' : '',
        isIlluminance ? '${measurement.luxMin ?? 0}' : '',
        isIlluminance ? (measurement.luxAvg ?? 0.0).toStringAsFixed(1) : '',
        isIlluminance ? '${measurement.luxMax ?? 0}' : '',
        measurement.latitude?.toStringAsFixed(6) ?? '',
        measurement.longitude?.toStringAsFixed(6) ?? '',
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
