import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole {
  @JsonValue('docente')
  docente,
  @JsonValue('estudiante')
  estudiante,
}

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.docente:
        return 'Docente';
      case UserRole.estudiante:
        return 'Estudiante';
    }
  }

  String get description {
    switch (this) {
      case UserRole.docente:
        return 'Creo grupos, proyectos y tareas. Designo jefes y superviso.';
      case UserRole.estudiante:
        return 'Me uno a grupos, oferto en tareas, voto y veo mi carga.';
    }
  }
}

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    required UserRole role,
    @Default([]) List<String> skills,
    @Default([]) List<String> groupIds,
    @Default(0) int createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

extension AppUserX on AppUser {
  bool get isDocente => role == UserRole.docente;
  bool get isEstudiante => role == UserRole.estudiante;

  AppUser copyWithTimestamp() => copyWith(createdAt: DateTime.now().millisecondsSinceEpoch);
}