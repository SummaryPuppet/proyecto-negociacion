import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/features/projects/data/project_repository.dart';
import 'package:repartojusto/features/projects/domain/project.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/groups/application/group_providers.dart';
import 'package:repartojusto/features/groups/domain/app_group.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) => ProjectRepository());

/// Stream de los proyectos de un grupo.
final projectsProvider = StreamProvider.family<List<Project>, String>((ref, groupId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects(groupId);
});

/// Stream de un proyecto específico.
final projectProvider = StreamProvider.family<Project?, ({String groupId, String projectId})>((ref, params) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProject(params.groupId, params.projectId);
});

/// Provider síncrono para acceso rápido al proyecto.
final projectSyncProvider = Provider.family<Project?, ({String groupId, String projectId})>((ref, params) {
  final asyncProject = ref.watch(projectProvider(params));
  return asyncProject.value;
});

/// Indica si el usuario es docente del proyecto (es docente del grupo).
final isProjectTeacherProvider = Provider.family<bool, ({String groupId, String projectId})>((ref, params) {
  final authState = ref.watch(authStateChangesProvider);
  final group = ref.watch(groupSyncProvider(params.groupId));
  if (authState.value == null || group == null) return false;
  return group.isTeacher(authState.value!.uid);
});