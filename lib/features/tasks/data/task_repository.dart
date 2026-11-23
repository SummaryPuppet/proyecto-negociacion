import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/tasks/domain/task.dart';
import 'package:repartojusto/core/errors/app_error.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksCollection(String groupId, String projectId) =>
      _firestore.collection('groups').doc(groupId).collection('projects').doc(projectId).collection('tasks');

  /// Crea una tarea (solo docente).
  Future<Result<Task>> createTask({
    required String groupId,
    required String projectId,
    required String title,
    required String description,
    required int weight,
    required int estHours,
    required List<String> skills,
  }) async {
    try {
      final taskRef = _tasksCollection(groupId, projectId).doc();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Obtener el orden actual (número de tareas existentes)
      final snapshot = await _tasksCollection(groupId, projectId).get();
      final order = snapshot.docs.length;

      final task = Task(
        id: taskRef.id,
        projectId: projectId,
        groupId: groupId,
        title: title.trim(),
        description: description.trim(),
        weight: weight,
        estHours: estHours,
        skills: skills,
        status: 'open',
        order: order,
        createdAt: now,
        updatedAt: now,
      );

      await taskRef.set(task.toJson());
      return Success(task);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Observa las tareas de un proyecto.
  Stream<List<Task>> watchTasks(String groupId, String projectId) {
    return _tasksCollection(groupId, projectId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromJson(doc.data()))
            .toList());
  }

  /// Observa una tarea específica.
  Stream<Task?> watchTask(String groupId, String projectId, String taskId) {
    return _tasksCollection(groupId, projectId)
        .doc(taskId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Task.fromJson(doc.data()!);
    });
  }

  /// Obtiene una tarea una sola vez.
  Future<Task?> getTask(String groupId, String projectId, String taskId) async {
    final doc = await _tasksCollection(groupId, projectId).doc(taskId).get();
    if (!doc.exists) return null;
    return Task.fromJson(doc.data()!);
  }

  /// Actualiza una tarea (solo docente para campos principales, estudiante para estado si es suya).
  Future<Result<void>> updateTask({
    required String groupId,
    required String projectId,
    required String taskId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _tasksCollection(groupId, projectId).doc(taskId).update(data);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Cambia el estado de la tarea (docente o estudiante asignado).
  Future<Result<void>> setStatus({
    required String groupId,
    required String projectId,
    required String taskId,
    required String status, // open, negotiating, assigned, done
    String? assigneeId,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (assigneeId != null) {
      data['assigneeId'] = assigneeId;
    } else if (status == 'open') {
      // Si se abre, quitar asignado
      data['assigneeId'] = FieldValue.delete();
    }
    return updateTask(
      groupId: groupId,
      projectId: projectId,
      taskId: taskId,
      data: data,
    );
  }

  /// Reordena tareas (solo docente).
  Future<Result<void>> reorderTasks({
    required String groupId,
    required String projectId,
    required List<String> taskIdsInOrder,
  }) async {
    try {
      final batch = _firestore.batch();
      for (var i = 0; i < taskIdsInOrder.length; i++) {
        final taskRef = _tasksCollection(groupId, projectId).doc(taskIdsInOrder[i]);
        batch.update(taskRef, {'order': i, 'updatedAt': DateTime.now().millisecondsSinceEpoch});
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Elimina una tarea (solo docente).
  Future<Result<void>> deleteTask(String groupId, String projectId, String taskId) async {
    try {
      await _tasksCollection(groupId, projectId).doc(taskId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Calcula los puntos totales del proyecto.
  Future<int> calculateTotalPoints(String groupId, String projectId) async {
    final snapshot = await _tasksCollection(groupId, projectId).get();
    return snapshot.docs.fold<int>(0, (sum, doc) => sum + (doc.data()['weight'] as int? ?? 0));
  }
}