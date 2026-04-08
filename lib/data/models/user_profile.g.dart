// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      age: fields[1] as int,
      gender: fields[2] as String,
      job: fields[3] as String,
      maritalStatus: fields[4] as String,
      birthDate: fields[5] as String?,
      birthCity: fields[6] as String?,
      zodiacSign: fields[7] as String?,
      onboardingComplete: fields[8] as bool,
      birthTime: fields[9] as String?,
      risingSign: fields[10] as String?,
      moonSign: fields[11] as String?,
      planet: fields[12] as String?,
      profilePicIndex: fields[13] as int?,
      customPhotoPath: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.job)
      ..writeByte(4)
      ..write(obj.maritalStatus)
      ..writeByte(5)
      ..write(obj.birthDate)
      ..writeByte(6)
      ..write(obj.birthCity)
      ..writeByte(7)
      ..write(obj.zodiacSign)
      ..writeByte(8)
      ..write(obj.onboardingComplete)
      ..writeByte(9)
      ..write(obj.birthTime)
      ..writeByte(10)
      ..write(obj.risingSign)
      ..writeByte(11)
      ..write(obj.moonSign)
      ..writeByte(12)
      ..write(obj.planet)
      ..writeByte(13)
      ..write(obj.profilePicIndex)
      ..writeByte(14)
      ..write(obj.customPhotoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
