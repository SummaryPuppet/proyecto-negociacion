import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String projectId,
    required String groupId,
    required String title,
    required String description,
    required int weight,          // puntos de la tarea
    required int estHours,        // horas estimadas
    @Default([]) List<String> skills, // habilidades requeridas
    @Default('open') String status,   // open, negotiating, assigned, done
    String? assigneeId,           // uid del estudiante asignado
    @Default(0) int order,        // orden en el proyecto
    @Default(0) int createdAt,
    @Default(0) int updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

extension TaskX on Task {
  bool get isOpen => status == 'open';
  bool get isNegotiating => status == 'negotiating';
  bool get isAssigned => status == 'assigned';
  bool get isDone => status == 'done';

  Task copyWithTimestamp() => copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
}