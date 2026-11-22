// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApprovalConfig _$ApprovalConfigFromJson(Map<String, dynamic> json) =>
    _ApprovalConfig(
      quorumPercent: (json['quorumPercent'] as num?)?.toInt() ?? 50,
      leaderVoteWeight: (json['leaderVoteWeight'] as num?)?.toInt() ?? 2,
      teacherCanOverride: json['teacherCanOverride'] as bool? ?? true,
    );

Map<String, dynamic> _$ApprovalConfigToJson(_ApprovalConfig instance) =>
    <String, dynamic>{
      'quorumPercent': instance.quorumPercent,
      'leaderVoteWeight': instance.leaderVoteWeight,
      'teacherCanOverride': instance.teacherCanOverride,
    };
