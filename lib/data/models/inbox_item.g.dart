// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InboxItemAdapter extends TypeAdapter<InboxItem> {
  @override
  final int typeId = 1;

  @override
  InboxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InboxItem(
      id: fields[0] as String,
      title: fields[1] as String,
      text: fields[2] as String,
      date: fields[3] as String,
      isRead: fields[4] as bool,
      fortuneTypeKey: fields[5] as String,
      photoPath1: fields[6] as String?,
      photoPath2: fields[7] as String?,
      photoPath3: fields[8] as String?,
      iconAsset: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InboxItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isRead)
      ..writeByte(5)
      ..write(obj.fortuneTypeKey)
      ..writeByte(6)
      ..write(obj.photoPath1)
      ..writeByte(7)
      ..write(obj.photoPath2)
      ..writeByte(8)
      ..write(obj.photoPath3)
      ..writeByte(9)
      ..write(obj.iconAsset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
