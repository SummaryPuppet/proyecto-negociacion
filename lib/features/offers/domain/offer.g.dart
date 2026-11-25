// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Offer _$OfferFromJson(Map<String, dynamic> json) => _Offer(
  id: json['id'] as String,
  taskId: json['taskId'] as String,
  projectId: json['projectId'] as String,
  groupId: json['groupId'] as String,
  authorId: json['authorId'] as String,
  points: (json['points'] as num).toInt(),
  hours: (json['hours'] as num).toInt(),
  argument: json['argument'] as String,
  parentOfferId: json['parentOfferId'] as String?,
  status: json['status'] as String? ?? 'pending',
  votes:
      (json['votes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  resolvedAt: (json['resolvedAt'] as num?)?.toInt(),
  resolvedBy: json['resolvedBy'] as String?,
  resolution: json['resolution'] as String?,
  createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$OfferToJson(_Offer instance) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'projectId': instance.projectId,
  'groupId': instance.groupId,
  'authorId': instance.authorId,
  'points': instance.points,
  'hours': instance.hours,
  'argument': instance.argument,
  'parentOfferId': instance.parentOfferId,
  'status': instance.status,
  'votes': instance.votes,
  'resolvedAt': instance.resolvedAt,
  'resolvedBy': instance.resolvedBy,
  'resolution': instance.resolution,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
