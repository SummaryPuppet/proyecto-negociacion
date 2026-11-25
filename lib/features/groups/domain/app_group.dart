
import 'package:freezed_annotation/freezed_annotation.dart';
import 'approval_config.dart';

part 'app_group.freezed.dart';
part 'app_group.g.dart';

@freezed
abstract class AppGroup with _$AppGroup {
  @JsonSerializable(explicitToJson: true)
  const factory AppGroup({
    required String id,
    required String name,
    required String period,
    required String teacherId,
    @Default('') String leaderId,
    @Default([]) List<String> memberIds,
    required String joinCode,
    @Default(ApprovalConfig()) ApprovalConfig approvalConfig,
    @Default(0) int createdAt,
  }) = _AppGroup;

  factory AppGroup.fromJson(Map<String, dynamic> json) =>
      _$AppGroupFromJson(json);
}

extension AppGroupX on AppGroup {
  bool isMember(String uid) => memberIds.contains(uid);
  bool isTeacher(String uid) => teacherId == uid;
  bool isLeader(String uid) => leaderId == uid;
  bool get hasLeader => leaderId.isNotEmpty;

  AppGroup copyWithTimestamp() =>
      copyWith(createdAt: DateTime.now().millisecondsSinceEpoch);
}
