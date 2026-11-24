import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/features/tasks/data/comment_repository.dart';
import 'package:repartojusto/features/tasks/domain/task_comment.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/auth/domain/app_user.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

final taskCommentsProvider =
    StreamProvider.family<
      List<TaskComment>,
      ({String groupId, String projectId, String taskId})
    >((ref, params) {
      final repository = ref.watch(commentRepositoryProvider);

      return repository.watchComments(
        groupId: params.groupId,
        projectId: params.projectId,
        taskId: params.taskId,
      );
    });

/// Obtiene el perfil del autor de un comentario.
final commentAuthorProvider = FutureProvider.family<AppUser?, String>((
  ref,
  uid,
) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getProfile(uid);
});
