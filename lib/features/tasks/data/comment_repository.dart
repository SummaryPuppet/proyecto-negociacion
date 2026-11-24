import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repartojusto/features/tasks/domain/task_comment.dart';

class CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _commentsCollection(
    String groupId,
    String projectId,
    String taskId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .collection('comments');
  }

  /// Observa los comentarios de una tarea en tiempo real.
  Stream<List<TaskComment>> watchComments({
    required String groupId,
    required String projectId,
    required String taskId,
  }) {
    return _commentsCollection(
      groupId,
      projectId,
      taskId,
    ).orderBy('createdAt').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskComment.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Publica un comentario en una tarea.
  Future<void> addComment({
    required String groupId,
    required String projectId,
    required String taskId,
    required String authorId,
    required String message,
  }) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      throw ArgumentError('El comentario no puede estar vacío.');
    }

    await _commentsCollection(groupId, projectId, taskId).add({
      'authorId': authorId,
      'message': cleanMessage,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
