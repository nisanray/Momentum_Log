// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_prefs.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPrefsAdapter extends TypeAdapter<UserPrefs> {
  @override
  final int typeId = 2;

  @override
  UserPrefs read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPrefs(
      lastUserId: fields[0] as String,
      lastUserEmail: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserPrefs obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lastUserId)
      ..writeByte(1)
      ..write(obj.lastUserEmail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPrefsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
