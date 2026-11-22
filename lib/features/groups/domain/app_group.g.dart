// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppGroup _$AppGroupFromJson(Map<String, dynamic> json) => _AppGroup(
  id: json['id'] as String,
  name: json['name'] as String,
  period: json['period'] as String,
  teacherId: json['teacherId'] as String,
  leaderId: json['leaderId'] as String? ?? '',
  memberIds:
      (json['memberIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  joinCode: json['joinCode'] as String,
  approvalConfig: json['approvalConfig'] == null
      ? const ApprovalConfig()
      : ApprovalConfig.fromJson(json['approvalConfig'] as Map<String, dynamic>),
  createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AppGroupToJson(_AppGroup instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'period': instance.period,
  'teacherId': instance.teacherId,
  'leaderId': instance.leaderId,
  'memberIds': instance.memberIds,
  'joinCode': instance.joinCode,
  'approvalConfig': instance.approvalConfig,
  'createdAt': instance.createdAt,
};
