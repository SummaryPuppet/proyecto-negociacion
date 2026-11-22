import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/groups/data/group_repository.dart';
import 'package:repartojusto/features/groups/domain/app_group.dart';
import 'package:repartojusto/features/groups/domain/approval_config.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) => GroupRepository());

/// Stream de los grupos del usuario actual.
final myGroupsProvider = StreamProvider<List<AppGroup>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final repo = ref.watch(groupRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return repo.watchMyGroups(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Stream de un grupo específico.
final groupProvider = StreamProvider.family<AppGroup?, String>((ref, groupId) {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.watchGroup(groupId);
});

/// Provider síncrono para acceso rápido al grupo.
final groupSyncProvider = Provider.family<AppGroup?, String>((ref, groupId) {
  final asyncGroup = ref.watch(groupProvider(groupId));
  return asyncGroup.value;
});

/// Indica si el usuario es docente del grupo.
final isGroupTeacherProvider = Provider.family<bool, String>((ref, groupId) {
  final authState = ref.watch(authStateChangesProvider);
  final group = ref.watch(groupSyncProvider(groupId));
  if (authState.value == null || group == null) return false;
  return group.isTeacher(authState.value!.uid);
});

/// Indica si el usuario es jefe del grupo.
final isGroupLeaderProvider = Provider.family<bool, String>((ref, groupId) {
  final authState = ref.watch(authStateChangesProvider);
  final group = ref.watch(groupSyncProvider(groupId));
  if (authState.value == null || group == null) return false;
  return group.isLeader(authState.value!.uid);
});

/// Indica si el grupo tiene jefe.
final groupHasLeaderProvider = Provider.family<bool, String>((ref, groupId) {
  final group = ref.watch(groupSyncProvider(groupId));
  return group?.hasLeader ?? false;
});

/// Configuración de aprobación del grupo.
final groupApprovalConfigProvider = Provider.family<ApprovalConfig?, String>((ref, groupId) {
  final group = ref.watch(groupSyncProvider(groupId));
  return group?.approvalConfig;
});