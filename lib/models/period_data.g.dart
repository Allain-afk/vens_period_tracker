// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PeriodDataAdapter extends TypeAdapter<PeriodData> {
  @override
  final int typeId = 0;

  @override
  PeriodData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PeriodData(
      startDate: fields[0] as DateTime,
      endDate: fields[1] as DateTime?,
      flowIntensity: fields[2] as String,
      symptoms: (fields[3] as List).cast<String>(),
      mood: fields[4] as String,
      notes: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PeriodData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.flowIntensity)
      ..writeByte(3)
      ..write(obj.symptoms)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
