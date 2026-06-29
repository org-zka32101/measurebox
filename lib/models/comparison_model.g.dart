// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComparisonModelAdapter extends TypeAdapter<ComparisonModel> {
  @override
  final int typeId = 3;

  @override
  ComparisonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComparisonModel(
      id: fields[0] as String,
      projectId: fields[1] as String,
      beforeMeasurementId: fields[2] as String,
      afterMeasurementId: fields[3] as String,
      improvementDb: fields[4] as double,
      improvementRate: fields[5] as double,
      createdAt: fields[6] as DateTime,
      memo: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ComparisonModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.beforeMeasurementId)
      ..writeByte(3)
      ..write(obj.afterMeasurementId)
      ..writeByte(4)
      ..write(obj.improvementDb)
      ..writeByte(5)
      ..write(obj.improvementRate)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.memo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
