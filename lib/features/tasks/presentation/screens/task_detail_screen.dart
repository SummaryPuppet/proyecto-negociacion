import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/projects/application/project_providers.dart';
import 'package:repartojusto/features/tasks/application/task_providers.dart';
import 'package:repartojusto/features/tasks/data/task_repository.dart';
import 'package:repartojusto/features/tasks/domain/task.dart';
import 'offer_list.dart';
class TaskDetailScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (groupId: groupId, projectId: projectId, taskId: taskId);
    final taskAsync = ref.watch(taskProvider(params));
    final projectParams = (groupId: groupId, projectId: projectId);
    final projectAsync = ref.watch(projectProvider(projectParams));
    final isTeacher = ref.watch(isProjectTeacherProvider(projectParams));

    return Scaffold(
      appBar: AppBar(
        title: taskAsync.when(
          data: (t) => Text(t?.title ?? 'Cargando...'),
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          if (isTeacher)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                const PopupMenuItem(value: 'force', child: Text('Forzar asignación')),
              ],
            ),
        ],
      ),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            return ErrorScreen(
              message: 'Tarea no encontrada',
              onRetry: () => ref.invalidate(taskProvider(params)),
            );
          }
          return Column(
                children: [
                  Expanded(
                    child: _buildTaskContent(context, ref, task),
                  ),
                  OfferList(
                    projectId: projectId,
                    taskId: taskId,
                    isGroupLeader: false, // Luego lo cambiaremos por la variable real
                    isTeacher: isTeacher,
                  ),
                ],
              );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorScreen(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(taskProvider(params)),
        ),
      ),
    );
  }

  Widget _buildTaskContent(
    BuildContext context,
    WidgetRef ref,
    Task task,
    dynamic project,
    bool isTeacher,
  ) {
    final projectIsNegotiating = project?.isNegotiating ?? false;
    final canOffer = projectIsNegotiating && task.isOpen;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info principal
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            if (task.isAssigned) ...[
                              const SizedBox(width: 8),
                              StatusChip(
                                label: 'Asignada',
                                status: StatusType.success,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description.isEmpty ? 'Sin descripción' : task.description,
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
                      ),
                      const SizedBox(height: 12),
                      _StatCircle(
                        value: task.estHours,
                        label: 'Horas est.',
                        color: Theme.of(context).colorScheme.primary,
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
                  children: task.skills
                      .map((s) => Chip(
                            label: Text(s),
                            avatar: const Icon(Icons.code_outlined, size: 16),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botón de oferta (Fase 3)
        if (canOffer)
          FilledButton.icon(
            onPressed: () {
              showAppSnackBar(context, 'Ofertas disponibles en la Fase 3');
            },
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('Hacer oferta'),
          ),

        // Ofertas (Fase 3)
        SectionDivider(label: 'Ofertas'),
        AppCard(
          child: Column(
            children: [
              const Icon(Icons.gavel_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Sistema de ofertas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Las ofertas, votos y contraofertas estarán disponibles en la Fase 3.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Comentarios (Fase 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionDivider(label: 'Comentarios'),
            TextButton.icon(
              onPressed: () => showAppSnackBar(context, 'Comentarios disponibles en la Fase 4'),
              icon: const Icon(Icons.add_comment, size: 18),
              label: const Text('Comentar'),
            ),
          ],
        ),
        AppCard(
          child: Column(
            children: [
              const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Sistema de comentarios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'El hilo de discusión por tarea estará disponible en la Fase 4.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        showAppSnackBar(context, 'Editar tarea (pendiente)');
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
      case 'force':
        showAppSnackBar(context, 'Forzar asignación disponible en la Fase 3');
        break;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar tarea',
      message: 'Se eliminarán sus ofertas y comentarios. ¿Seguro?',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(taskRepositoryProvider).deleteTask(groupId, projectId, taskId);
    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          context.go('/groups/$groupId/projects/$projectId');
          showAppSnackBar(context, 'Tarea eliminada');
        },
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Asignada';
      case 'negotiating':
        return 'En negociación';
      case 'open':
        return 'Abierta';
      case 'done':
        return 'Completada';
      default:
        return status;
    }
  }

  StatusType _statusType(String status) {
    switch (status) {
      case 'assigned':
        return StatusType.success;
      case 'negotiating':
        return StatusType.warning;
      case 'open':
        return StatusType.info;
      case 'done':
        return StatusType.neutral;
      default:
        return StatusType.neutral;
    }
  }
}

class _StatCircle extends StatelessWidget {
  const _StatCircle({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
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