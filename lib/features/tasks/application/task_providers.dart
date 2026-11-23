import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/features/tasks/data/task_repository.dart';
import 'package:repartojusto/features/tasks/domain/task.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository());

/// Stream de las tareas de un proyecto.
final tasksProvider = StreamProvider.family<List<Task>, ({String groupId, String projectId})>((ref, params) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks(params.groupId, params.projectId);
});

/// Stream de una tarea específica.
final taskProvider = StreamProvider.family<Task?, ({String groupId, String projectId, String taskId})>((ref, params) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTask(params.groupId, params.projectId, params.taskId);
});

/// Provider síncrono para acceso rápido a la tarea.
final taskSyncProvider = Provider.family<Task?, ({String groupId, String projectId, String taskId})>((ref, params) {
  final asyncTask = ref.watch(taskProvider(params));
  return asyncTask.value;
});

/// Indica si el usuario es el asignado de la tarea.
final isTaskAssigneeProvider = Provider.family<bool, ({String groupId, String projectId, String taskId})>((ref, params) {
  final authState = ref.watch(authStateChangesProvider);
  final task = ref.watch(taskSyncProvider(params));
  if (authState.value == null || task == null) return false;
  return task.assigneeId == authState.value!.uid;
});

/// Indica si la tarea está asignada al usuario actual.
final isTaskAssignedToMeProvider = Provider.family<bool, ({String groupId, String projectId, String taskId})>((ref, params) {
  final authState = ref.watch(authStateChangesProvider);
  final task = ref.watch(taskSyncProvider(params));
  if (authState.value == null || task == null) return false;
  return task.isAssigned && task.assigneeId == authState.value!.uid;
});