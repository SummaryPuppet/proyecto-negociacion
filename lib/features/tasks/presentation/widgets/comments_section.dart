import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/tasks/application/comment_providers.dart';
import 'package:repartojusto/features/tasks/domain/task_comment.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final String groupId;
  final String projectId;
  final String taskId;

  const CommentsSection({
    super.key,
    required this.groupId,
    required this.projectId,
    required this.taskId,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final message = _controller.text.trim();

    if (message.isEmpty || _isSending) return;

    final user = ref.read(authStateChangesProvider).value;

    if (user == null) {
      _showMessage('Debes iniciar sesión para comentar.', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref
          .read(commentRepositoryProvider)
          .addComment(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            authorId: user.uid,
            message: message,
          );

      if (!mounted) return;

      _controller.clear();
      _showMessage('Comentario publicado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo publicar el comentario.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final params = (
      groupId: widget.groupId,
      projectId: widget.projectId,
      taskId: widget.taskId,
    );

    final commentsAsync = ref.watch(taskCommentsProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No se pudieron cargar los comentarios.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.forum_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Todavía no hay comentarios.'),
                      Text('¡Sé el primero en participar!'),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: comments
                  .map((comment) => _buildComment(comment))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Escribe tu comentario...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              tooltip: 'Publicar comentario',
              onPressed: _isSending ? null : _sendComment,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComment(TaskComment comment) {
    final authorAsync = ref.watch(commentAuthorProvider(comment.authorId));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            authorAsync.when(
              data: (author) => CircleAvatar(
                backgroundImage:
                    author?.photoUrl != null && author!.photoUrl!.isNotEmpty
                    ? NetworkImage(author.photoUrl!)
                    : null,
                child: author?.photoUrl == null || author!.photoUrl!.isEmpty
                    ? Text(
                        author?.name.isNotEmpty == true
                            ? author!.name[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              loading: () =>
                  const CircleAvatar(child: Icon(Icons.person_outline)),
              error: (_, __) =>
                  const CircleAvatar(child: Icon(Icons.person_outline)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  authorAsync.when(
                    data: (author) => Text(
                      author?.name ?? 'Usuario desconocido',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    loading: () => const Text('Cargando usuario...'),
                    error: (_, __) => const Text('Usuario desconocido'),
                  ),
                  const SizedBox(height: 4),
                  Text(comment.message),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
