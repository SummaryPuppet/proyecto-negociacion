// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  id: json['id'] as String,
  groupId: json['groupId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  totalPoints: (json['totalPoints'] as num).toInt(),
  negotiationDeadline: (json['negotiationDeadline'] as num).toInt(),
  deliveryDeadline: (json['deliveryDeadline'] as num).toInt(),
  status: json['status'] as String? ?? 'draft',
  createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'groupId': instance.groupId,
  'title': instance.title,
  'description': instance.description,
  'totalPoints': instance.totalPoints,
  'negotiationDeadline': instance.negotiationDeadline,
  'deliveryDeadline': instance.deliveryDeadline,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
