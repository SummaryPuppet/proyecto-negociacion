// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  photoUrl: json['photoUrl'] as String?,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  skills:
      (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  groupIds:
      (json['groupIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'name': instance.name,
  'email': instance.email,
  'photoUrl': instance.photoUrl,
  'role': _$UserRoleEnumMap[instance.role]!,
  'skills': instance.skills,
  'groupIds': instance.groupIds,
  'createdAt': instance.createdAt,
};

const _$UserRoleEnumMap = {
  UserRole.docente: 'docente',
  UserRole.estudiante: 'estudiante',
};
