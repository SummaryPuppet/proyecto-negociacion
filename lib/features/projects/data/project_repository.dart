import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/projects/domain/project.dart';
import 'package:repartojusto/core/errors/app_error.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _projectsCollection(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('projects');

  DocumentReference<Map<String, dynamic>> _groupRef(String groupId) =>
      _firestore.collection('groups').doc(groupId);

  /// Crea un proyecto (solo docente del grupo).
  Future<Result<Project>> createProject({
    required String groupId,
    required String title,
    required String description,
    required int negotiationDeadline,
    required int deliveryDeadline,
    required String teacherId,
  }) async {
    try {
      // Validar que el caller es el docente del grupo
      final groupDoc = await _groupRef(groupId).get();
      if (!groupDoc.exists) {
        return Failure(const BusinessError('Grupo no encontrado', 'group-not-found'));
      }
      final groupData = groupDoc.data()!;
      final groupTeacherId = groupData['teacherId'] as String?;
      if (groupTeacherId != teacherId) {
        return Failure(const PermissionError('Solo el docente del grupo puede crear proyectos', 'permission-denied'));
      }

      final projectRef = _projectsCollection(groupId).doc();
      final now = DateTime.now().millisecondsSinceEpoch;

      final project = Project(
        id: projectRef.id,
        groupId: groupId,
        title: title.trim(),
        description: description.trim(),
        totalPoints: 0, // Se actualiza al añadir tareas
        negotiationDeadline: negotiationDeadline,
        deliveryDeadline: deliveryDeadline,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      );

      await projectRef.set(project.toJson());
      return Success(project);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Observa los proyectos de un grupo.
  Stream<List<Project>> watchProjects(String groupId) {
    return _projectsCollection(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromJson(doc.data()))
            .toList());
  }

  /// Observa un proyecto específico.
  Stream<Project?> watchProject(String groupId, String projectId) {
    return _projectsCollection(groupId)
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Project.fromJson(doc.data()!);
    });
  }

  /// Obtiene un proyecto una sola vez.
  Future<Project?> getProject(String groupId, String projectId) async {
    final doc = await _projectsCollection(groupId).doc(projectId).get();
    if (!doc.exists) return null;
    return Project.fromJson(doc.data()!);
  }

  /// Actualiza un proyecto (solo docente).
  Future<Result<void>> updateProject({
    required String groupId,
    required String projectId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _projectsCollection(groupId).doc(projectId).update(data);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Cambia el estado del proyecto (solo docente).
  Future<Result<void>> setStatus({
    required String groupId,
    required String projectId,
    required String status,
  }) async {
    return updateProject(
      groupId: groupId,
      projectId: projectId,
      data: {'status': status, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
    );
  }

  /// Actualiza los puntos totales del proyecto (se llama al crear/borrar tareas).
  Future<Result<void>> updateTotalPoints({
    required String groupId,
    required String projectId,
    required int totalPoints,
  }) async {
    return updateProject(
      groupId: groupId,
      projectId: projectId,
      data: {'totalPoints': totalPoints, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
    );
  }

  /// Elimina un proyecto (solo docente).
  Future<Result<void>> deleteProject(String groupId, String projectId) async {
    try {
      await _projectsCollection(groupId).doc(projectId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }
}