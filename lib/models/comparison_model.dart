import 'package:hive/hive.dart';

part 'comparison_model.g.dart';

@HiveType(typeId: 3)
class ComparisonModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String beforeMeasurementId;

  @HiveField(3)
  String afterMeasurementId;

  @HiveField(4)
  double improvementDb;

  @HiveField(5)
  double improvementRate;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? memo;

  ComparisonModel({
    required this.id,
    required this.projectId,
    required this.beforeMeasurementId,
    required this.afterMeasurementId,
    required this.improvementDb,
    required this.improvementRate,
    required this.createdAt,
    this.memo,
  });

  ComparisonModel copyWith({
    String? id,
    String? projectId,
    String? beforeMeasurementId,
    String? afterMeasurementId,
    double? improvementDb,
    double? improvementRate,
    DateTime? createdAt,
    String? memo,
  }) {
    return ComparisonModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      beforeMeasurementId: beforeMeasurementId ?? this.beforeMeasurementId,
      afterMeasurementId: afterMeasurementId ?? this.afterMeasurementId,
      improvementDb: improvementDb ?? this.improvementDb,
      improvementRate: improvementRate ?? this.improvementRate,
      createdAt: createdAt ?? this.createdAt,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'beforeMeasurementId': beforeMeasurementId,
      'afterMeasurementId': afterMeasurementId,
      'improvement_dB': improvementDb,
      'improvement_rate': improvementRate,
      'createdAt': createdAt,
      'memo': memo,
    };
  }

  factory ComparisonModel.fromFirestore(
    Map<String, dynamic> data,
    String projectId,
  ) {
    return ComparisonModel(
      id: data['id'] ?? '',
      projectId: projectId,
      beforeMeasurementId: data['beforeMeasurementId'] ?? '',
      afterMeasurementId: data['afterMeasurementId'] ?? '',
      improvementDb: (data['improvement_dB'] as num?)?.toDouble() ?? 0.0,
      improvementRate: (data['improvement_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      memo: data['memo'],
    );
  }
}
