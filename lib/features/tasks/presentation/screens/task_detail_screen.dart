import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/utils.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({
    super.key,
    required this.groupId,
    required this.projectId,
    required this.taskId,
  });

  final String groupId;
  final String projectId;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    // TODO: Conectar con stream de la tarea
    final task = _MockTask(
      id: taskId,
      title: 'Backend API',
      description: 'Diseñar e implementar la API REST con Node.js/Express. Incluye autenticación, CRUD de tareas y WebSockets para tiempo real.',
      weight: 40,
      estHours: 15,
      status: 'negotiating',
      skills: ['Node.js', 'Express', 'MongoDB', 'WebSockets'],
      offers: [
        _MockOffer('o1', 'Carlos Ruiz', 40, 12, 'Tengo experiencia con Node y MongoDB. Puedo entregarlo en 10 días.', 'pending', 3, 1),
        _MockOffer('o2', 'María Torres', 35, 15, 'Prefiero menos puntos pero más tiempo para testing exhaustivo.', 'pending', 2, 0),
      ],
      comments: [
        _MockComment('c1', 'Carlos Ruiz', '¿Se permite usar NestJS en lugar de Express?', '10:30'),
        _MockComment('c2', 'Prof. García', 'Sí, siempre que cumpla la especificación de la API.', '10:45'),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Editar tarea (solo docente)
              } else if (value == 'force') {
                // TODO: Forzar asignación (docente/jefe)
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'force', child: Text('Forzar asignación')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info principal
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusChip(
                                label: _statusLabel(task.status),
                                status: _statusType(task.status),
                              ),
                              const SizedBox(width: 8),
                              if (task.status == 'assigned')
                                StatusChip(
                                  label: 'Asignada a ${task.assignee}',
                                  status: StatusType.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _StatCircle(
                          value: task.weight,
                          label: 'Puntos',
                          color: Colors.amber.shade700,
                          icon: Icons.star_rounded,
                        ),
                        const SizedBox(height: 12),
                        _StatCircle(
                          value: task.estHours,
                          label: 'Horas est.',
                          color: Theme.of(context).colorScheme.primary,
                          icon: Icons.access_time_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
                if (task.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: task.skills.map((s) => Chip(
                      label: Text(s),
                      avatar: Icon(Icons.code_outlined, size: 16),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ofertas
          SectionDivider(label: 'Ofertas (${task.offers.length})'),
          const SizedBox(height: 8),
          ...task.offers.map((o) => _OfferTile(offer: o, groupId: groupId, projectId: projectId, taskId: taskId)),
          if (task.offers.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Icon(Icons.gavel_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Sin ofertas aún',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sé el primero en ofertar por esta tarea',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/offers/new', extra: {
                      'groupId': groupId,
                      'projectId': projectId,
                      'taskId': taskId,
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Hacer oferta'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Comentarios
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionDivider(label: 'Comentarios (${task.comments.length})'),
              TextButton.icon(
                onPressed: () => _showCommentDialog(context),
                icon: const Icon(Icons.add_comment, size: 18),
                label: const Text('Comentar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...task.comments.map((c) => _CommentTile(comment: c)),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo comentario'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Escribe tu comentario...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Guardar comentario
              showAppSnackBar(context, 'Comentario enviado (simulado)');
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned': return 'Asignada';
      case 'negotiating': return 'En negociación';
      case 'open': return 'Abierta';
      case 'done': return 'Completada';
      default: return status;
    }
  }

  StatusType _statusType(String status) {
    switch (status) {
      case 'assigned': return StatusType.success;
      case 'negotiating': return StatusType.warning;
      case 'open': return StatusType.info;
      case 'done': return StatusType.neutral;
      default: return StatusType.neutral;
    }
  }
}

class _MockTask {
  final String id;
  final String title;
  final String description;
  final int weight;
  final int estHours;
  final String status;
  final List<String> skills;
  final List<_MockOffer> offers;
  final List<_MockComment> comments;
  String? assignee;

  _MockTask({
    required this.id,
    required this.title,
    required this.description,
    required this.weight,
    required this.estHours,
    required this.status,
    required this.skills,
    required this.offers,
    required this.comments,
  }) {
    if (status == 'assigned') assignee = 'Carlos Ruiz';
  }
}

class _MockOffer {
  final String id;
  final String studentName;
  final int points;
  final int hours;
  final String message;
  final String status;
  final int votesFor;
  final int votesAgainst;

  _MockOffer(this.id, this.studentName, this.points, this.hours, this.message, this.status, this.votesFor, this.votesAgainst);
}

class _MockComment {
  final String id;
  final String authorName;
  final String text;
  final String time;

  _MockComment(this.id, this.authorName, this.text, this.time);
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.groupId,
    required this.projectId,
    required this.taskId,
  });

  final _MockOffer offer;
  final String groupId;
  final String projectId;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: offer.studentName, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.studentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Pide ${offer.points} pts · ${offer.hours} h',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: _offerStatusLabel(offer.status),
                status: _offerStatusType(offer.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_outlined,
                count: offer.votesFor,
                color: Colors.green,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _VoteButton(
                icon: Icons.thumb_down_outlined,
                count: offer.votesAgainst,
                color: Colors.red,
                onTap: () {},
              ),
              const Spacer(),
              if (offer.status == 'pending')
                TextButton.icon(
                  onPressed: () {
                    // TODO: Contraoferta
                    showAppSnackBar(context, 'Contraoferta (pendiente)');
                  },
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Contraofertar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _offerStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'accepted': return 'Aceptada';
      case 'rejected': return 'Rechazada';
      case 'withdrawn': return 'Retirada';
      default: return status;
    }
  }

  StatusType _offerStatusType(String status) {
    switch (status) {
      case 'accepted': return StatusType.success;
      case 'rejected': return StatusType.error;
      case 'withdrawn': return StatusType.neutral;
      default: return StatusType.warning;
    }
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final _MockComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: comment.authorName, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  const _StatCircle({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}