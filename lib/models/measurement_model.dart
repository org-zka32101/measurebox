import 'package:hive/hive.dart';
import 'measurement_category.dart';
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

  /// What was measured (sound vs. vibration). See [MeasurementCategory] for
  /// why this defaults to `0` (sound) for records written before this field
  /// existed.
  @HiveField(14)
  int category;

  /// Vibration magnitude (m/s², gravity already excluded — see
  /// VibrationService), mirroring dbValue/dbMin/dbAvg/dbMax's shape.
  /// Null for non-vibration measurements.
  @HiveField(15)
  double? vibrationValue;

  @HiveField(16)
  double? vibrationMin;

  @HiveField(17)
  double? vibrationAvg;

  @HiveField(18)
  double? vibrationMax;

  /// Where the measurement was recorded (from LocationService). Both null
  /// unless the user opted in to location tagging when saving — GPS access
  /// is never requested implicitly.
  @HiveField(19)
  double? latitude;

  @HiveField(20)
  double? longitude;

  /// Illuminance (lux) — Android only, see IlluminanceService. Null for
  /// non-illuminance measurements. luxValue/Min/Max are int (matching
  /// light_sensor's Stream<int>); luxAvg is double since it's a mean.
  @HiveField(21)
  int? luxValue;

  @HiveField(22)
  int? luxMin;

  @HiveField(23)
  double? luxAvg;

  @HiveField(24)
  int? luxMax;

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
    this.category = 0,
    this.vibrationValue,
    this.vibrationMin,
    this.vibrationAvg,
    this.vibrationMax,
    this.latitude,
    this.longitude,
    this.luxValue,
    this.luxMin,
    this.luxAvg,
    this.luxMax,
  });

  MeasurementType get measurementType =>
      MeasurementType.values[type
          .clamp(0, MeasurementType.values.length - 1)
          .toInt()];

  MeasurementCategory get measurementCategory =>
      MeasurementCategory.values[category.clamp(
        0,
        MeasurementCategory.values.length - 1,
      )];

  bool get hasLocation => latitude != null && longitude != null;

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
    int? category,
    double? vibrationValue,
    double? vibrationMin,
    double? vibrationAvg,
    double? vibrationMax,
    double? latitude,
    double? longitude,
    int? luxValue,
    int? luxMin,
    double? luxAvg,
    int? luxMax,
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
      category: category ?? this.category,
      vibrationValue: vibrationValue ?? this.vibrationValue,
      vibrationMin: vibrationMin ?? this.vibrationMin,
      vibrationAvg: vibrationAvg ?? this.vibrationAvg,
      vibrationMax: vibrationMax ?? this.vibrationMax,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      luxValue: luxValue ?? this.luxValue,
      luxMin: luxMin ?? this.luxMin,
      luxAvg: luxAvg ?? this.luxAvg,
      luxMax: luxMax ?? this.luxMax,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': measurementType.name,
      'category': measurementCategory.name,
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
      'vibration_value': vibrationValue,
      'vibration_min': vibrationMin,
      'vibration_avg': vibrationAvg,
      'vibration_max': vibrationMax,
      'latitude': latitude,
      'longitude': longitude,
      'lux_value': luxValue,
      'lux_min': luxMin,
      'lux_avg': luxAvg,
      'lux_max': luxMax,
    };
  }

  factory MeasurementModel.fromFirestore(
    Map<String, dynamic> data,
    String projectId,
  ) {
    final typeStr = data['type'] as String? ?? 'single';
    final type = MeasurementType.values.asNameMap()[typeStr]?.index ?? 0;

    // 'category' キーが無いドキュメントは、この機能が追加される前の
    // 既存の騒音測定データなので 'sound' として扱う。
    final categoryStr = data['category'] as String? ?? 'sound';
    final category =
        MeasurementCategory.values.asNameMap()[categoryStr]?.index ?? 0;

    return MeasurementModel(
      id: data['id'] ?? '',
      projectId: projectId,
      type: type,
      dbValue: (data['dB_value'] as num?)?.toDouble() ?? 0.0,
      dbMin: (data['dB_min'] as num?)?.toDouble() ?? 0.0,
      dbAvg: (data['dB_avg'] as num?)?.toDouble() ?? 0.0,
      dbMax: (data['dB_max'] as num?)?.toDouble() ?? 0.0,
      durationMs: data['duration_ms'] as int? ?? 0,
      timestamp: data['timestamp'] is DateTime
          ? data['timestamp'] as DateTime
          : (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      memo: data['memo'],
      calibrationOffset:
          (data['calibration_offset'] as num?)?.toDouble() ?? 0.0,
      deviceInfo: data['device_info'] ?? '',
      peakFrequency: (data['peak_frequency'] as num?)?.toDouble(),
      dominantFrequencies: (data['dominant_frequencies'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      category: category,
      vibrationValue: (data['vibration_value'] as num?)?.toDouble(),
      vibrationMin: (data['vibration_min'] as num?)?.toDouble(),
      vibrationAvg: (data['vibration_avg'] as num?)?.toDouble(),
      vibrationMax: (data['vibration_max'] as num?)?.toDouble(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      luxValue: (data['lux_value'] as num?)?.toInt(),
      luxMin: (data['lux_min'] as num?)?.toInt(),
      luxAvg: (data['lux_avg'] as num?)?.toDouble(),
      luxMax: (data['lux_max'] as num?)?.toInt(),
    );
  }
}
