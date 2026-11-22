import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_config.freezed.dart';
part 'approval_config.g.dart';

@freezed
abstract class ApprovalConfig with _$ApprovalConfig {
  const factory ApprovalConfig({
    @Default(50) int quorumPercent,
    @Default(2) int leaderVoteWeight,
    @Default(true) bool teacherCanOverride,
  }) = _ApprovalConfig;

  factory ApprovalConfig.fromJson(Map<String, dynamic> json) => _$ApprovalConfigFromJson(json);
}

extension ApprovalConfigX on ApprovalConfig {
  int votesNeeded(int totalMembers) {
    return (totalMembers * quorumPercent / 100).ceil();
  }
}