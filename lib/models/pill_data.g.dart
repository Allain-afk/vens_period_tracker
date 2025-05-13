part of 'pill_data.dart';

// **************************************************************************
// Please Do Not Modify This File - Allain
// **************************************************************************

class PillDataAdapter extends TypeAdapter<PillData> {
  @override
  final int typeId = 2;

  @override
  PillData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PillData(
      contraceptiveMethod: fields[0] as String,
      activePillCount: fields[1] as int,
      placeboPillCount: fields[2] as int,
      startDate: fields[3] as DateTime,
      nextRefillDate: fields[4] as DateTime,
      reminderTime: fields[5] as String,
      reminderEnabled: fields[6] as bool,
      pillLogs: (fields[7] as List).cast<PillLogEntry>(),
      brandName: fields[8] as String,
      preAlarmEnabled: fields[9] as bool,
      preAlarmMinutes: fields[10] as int,
      autoSnoozeEnabled: fields[11] as bool,
      autoSnoozeMinutes: fields[12] as int,
      autoSnoozeRepeat: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PillData obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.contraceptiveMethod)
      ..writeByte(1)
      ..write(obj.activePillCount)
      ..writeByte(2)
      ..write(obj.placeboPillCount)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.nextRefillDate)
      ..writeByte(5)
      ..write(obj.reminderTime)
      ..writeByte(6)
      ..write(obj.reminderEnabled)
      ..writeByte(7)
      ..write(obj.pillLogs)
      ..writeByte(8)
      ..write(obj.brandName)
      ..writeByte(9)
      ..write(obj.preAlarmEnabled)
      ..writeByte(10)
      ..write(obj.preAlarmMinutes)
      ..writeByte(11)
      ..write(obj.autoSnoozeEnabled)
      ..writeByte(12)
      ..write(obj.autoSnoozeMinutes)
      ..writeByte(13)
      ..write(obj.autoSnoozeRepeat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PillDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PillLogEntryAdapter extends TypeAdapter<PillLogEntry> {
  @override
  final int typeId = 3;

  @override
  PillLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PillLogEntry(
      date: fields[0] as DateTime,
      taken: fields[1] as bool,
      status: fields[2] as String,
      takenTime: fields[3] as DateTime?,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PillLogEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.taken)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.takenTime)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PillLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
