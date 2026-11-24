// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  groupId: json['groupId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  weight: (json['weight'] as num).toInt(),
  estHours: (json['estHours'] as num).toInt(),
  skills:
      (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  status: json['status'] as String? ?? 'open',
  assigneeId: json['assigneeId'] as String?,
  order: (json['order'] as num?)?.toInt() ?? 0,
  createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'groupId': instance.groupId,
  'title': instance.title,
  'description': instance.description,
  'weight': instance.weight,
  'estHours': instance.estHours,
  'skills': instance.skills,
  'status': instance.status,
  'assigneeId': instance.assigneeId,
  'order': instance.order,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
