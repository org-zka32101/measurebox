// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementModelAdapter extends TypeAdapter<MeasurementModel> {
  @override
  final int typeId = 2;

  @override
  MeasurementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementModel(
      id: fields[0] as String,
      projectId: fields[1] as String,
      type: fields[2] as int,
      dbValue: fields[3] as double,
      dbMin: fields[4] as double,
      dbAvg: fields[5] as double,
      dbMax: fields[6] as double,
      durationMs: fields[7] as int,
      timestamp: fields[8] as DateTime,
      memo: fields[9] as String?,
      calibrationOffset: fields[10] as double,
      deviceInfo: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.dbValue)
      ..writeByte(4)
      ..write(obj.dbMin)
      ..writeByte(5)
      ..write(obj.dbAvg)
      ..writeByte(6)
      ..write(obj.dbMax)
      ..writeByte(7)
      ..write(obj.durationMs)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.memo)
      ..writeByte(10)
      ..write(obj.calibrationOffset)
      ..writeByte(11)
      ..write(obj.deviceInfo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
