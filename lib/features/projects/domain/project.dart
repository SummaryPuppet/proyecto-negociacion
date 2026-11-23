import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String groupId,
    required String title,
    required String description,
    required int totalPoints,
    required int negotiationDeadline, // epoch millis
    required int deliveryDeadline,   // epoch millis
    @Default('draft') String status, // draft, negotiating, assigned, closed
    @Default(0) int createdAt,
    @Default(0) int updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}

extension ProjectX on Project {
  bool get isNegotiating => status == 'negotiating';
  bool get isAssigned => status == 'assigned';
  bool get isClosed => status == 'closed';
  bool get isDraft => status == 'draft';

  Project copyWithTimestamp() => copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
}