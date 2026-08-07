import 'package:hive/hive.dart';
import 'measurement_type.dart';

part 'measurement_model.g.dart';

@HiveType(typeId: 2)
class MeasurementModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  int type; // MeasurementType index

  @HiveField(3)
  double dbValue;

  @HiveField(4)
  double dbMin;

  @HiveField(5)
  double dbAvg;

  @HiveField(6)
  double dbMax;

  @HiveField(7)
  int durationMs;

  @HiveField(8)
  DateTime timestamp;

  @HiveField(9)
  String? memo;

  @HiveField(10)
  double calibrationOffset;

  @HiveField(11)
  String deviceInfo;

  /// Peak (dominant) frequency detected during the measurement, in Hz.
  /// Null for measurements taken before frequency analysis was added, or
  /// for dB-only measurements.
  @HiveField(12)
  double? peakFrequency;

  /// Up to a handful of secondary dominant frequencies (Hz) detected
  /// alongside [peakFrequency], loudest first.
  @HiveField(13)
  List<double>? dominantFrequencies;

  MeasurementModel({
    required this.id,
    required this.projectId,
    required this.type,
    required this.dbValue,
    required this.dbMin,
    required this.dbAvg,
    required this.dbMax,
    required this.durationMs,
    required this.timestamp,
    this.memo,
    this.calibrationOffset = 0.0,
    this.deviceInfo = '',
    this.peakFrequency,
    this.dominantFrequencies,
  });

  MeasurementType get measurementType =>
      MeasurementType.values[
          type.clamp(0, MeasurementType.values.length - 1).toInt()];

  MeasurementModel copyWith({
    String? id,
    String? projectId,
    int? type,
    double? dbValue,
    double? dbMin,
    double? dbAvg,
    double? dbMax,
    int? durationMs,
    DateTime? timestamp,
    String? memo,
    double? calibrationOffset,
    String? deviceInfo,
    double? peakFrequency,
    List<double>? dominantFrequencies,
  }) {
    return MeasurementModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      dbValue: dbValue ?? this.dbValue,
      dbMin: dbMin ?? this.dbMin,
      dbAvg: dbAvg ?? this.dbAvg,
      dbMax: dbMax ?? this.dbMax,
      durationMs: durationMs ?? this.durationMs,
      timestamp: timestamp ?? this.timestamp,
      memo: memo ?? this.memo,
      calibrationOffset: calibrationOffset ?? this.calibrationOffset,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      peakFrequency: peakFrequency ?? this.peakFrequency,
      dominantFrequencies: dominantFrequencies ?? this.dominantFrequencies,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': measurementType.name,
      'dB_value': dbValue,
      'dB_min': dbMin,
      'dB_avg': dbAvg,
      'dB_max': dbMax,
      'duration_ms': durationMs,
      'timestamp': timestamp,
      'memo': memo,
      'calibration_offset': calibrationOffset,
      'device_info': deviceInfo,
      'peak_frequency': peakFrequency,
      'dominant_frequencies': dominantFrequencies,
    };
  }

  factory MeasurementModel.fromFirestore(
    Map<String, dynamic> data,
    String projectId,
  ) {
    final typeStr = data['type'] as String? ?? 'single';
    final type = MeasurementType.values.asNameMap()[typeStr]?.index ?? 0;

    return MeasurementModel(
      id: data['id'] ?? '',
      projectId: projectId,
      type: type,
      dbValue: (data['dB_value'] as num?)?.toDouble() ?? 0.0,
      dbMin: (data['dB_min'] as num?)?.toDouble() ?? 0.0,
      dbAvg: (data['dB_avg'] as num?)?.toDouble() ?? 0.0,
      dbMax: (data['dB_max'] as num?)?.toDouble() ?? 0.0,
      durationMs: data['duration_ms'] as int? ?? 0,
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      memo: data['memo'],
      calibrationOffset: (data['calibration_offset'] as num?)?.toDouble() ?? 0.0,
      deviceInfo: data['device_info'] ?? '',
      peakFrequency: (data['peak_frequency'] as num?)?.toDouble(),
      dominantFrequencies: (data['dominant_frequencies'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}
