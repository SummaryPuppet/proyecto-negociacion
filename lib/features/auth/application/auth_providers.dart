import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/auth/data/auth_repository.dart';
import 'package:repartojusto/features/auth/data/user_repository.dart';
import 'package:repartojusto/features/auth/domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

/// Stream del usuario de Firebase Auth (null si no hay sesión).
final authStateChangesProvider = StreamProvider<firebase_auth.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Stream del perfil completo del usuario (null si no hay sesión o no existe perfil).
final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return userRepository.watchProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider síncrono del perfil actual (útil para comprobaciones rápidas).
final currentProfileSyncProvider = Provider<AppUser?>((ref) {
  final asyncProfile = ref.watch(currentProfileProvider);
  return asyncProfile.value;
});

/// Provider del rol actual (útil para UI condicional).
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final profile = ref.watch(currentProfileSyncProvider);
  return profile?.role;
});

/// Indica si hay sesión activa.
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.hasValue && authState.value != null;
});

/// Indica si el perfil está cargando.
final isProfileLoadingProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile.isLoading;
});

/// Indica si el usuario ya eligió rol (tiene perfil).
final hasChosenRoleProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileSyncProvider);
  return profile != null;
});

/// Provider para obtener el nombre de un usuario por UID (para mostrar en ofertas, etc.)
final userNameProvider = FutureProvider.family<String?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  final userRepository = ref.watch(userRepositoryProvider);
  final profile = await userRepository.getProfile(uid);
  return profile?.name;
});