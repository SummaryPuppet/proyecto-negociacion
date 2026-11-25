import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/features/tasks/presentation/widgets/comments_section.dart';
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/projects/application/project_providers.dart';
import 'package:repartojusto/features/projects/domain/project.dart';
import 'package:repartojusto/features/tasks/application/task_providers.dart';
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
                const PopupMenuItem(
                  value: 'force',
                  child: Text('Forzar asignación'),
                ),
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
                child: _buildTaskContent(
                  context,
                  ref,
                  task,
                  projectAsync.value,
                  isTeacher,
                ),
              ),
              OfferList(
                groupId: groupId,
                projectId: projectId,
                taskId: taskId,
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
    Project? project,
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
                          task.description.isEmpty
                              ? 'Sin descripción'
                              : task.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // Asignado a - mostrar nombre si está asignada
                        if (task.isAssigned && task.assigneeId != null) ...[
                          const SizedBox(height: 16),
                          _AssigneeDisplay(assigneeId: task.assigneeId!),
                        ],
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
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          avatar: const Icon(Icons.code_outlined, size: 16),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botón de oferta
        if (canOffer)
          FilledButton.icon(
            onPressed: () {
              context.pushNamed(
                'newOffer',
                extra: {
                  'groupId': groupId,
                  'projectId': projectId,
                  'taskId': taskId,
                },
              );
            },
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('Hacer oferta'),
          ),

        const SizedBox(height: 16),

        // Comentarios de la tarea
        SectionDivider(label: 'Comentarios'),
        const SizedBox(height: 8),
        AppCard(
          child: CommentsSection(
            groupId: groupId,
            projectId: projectId,
            taskId: taskId,
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

    final result = await ref
        .read(taskRepositoryProvider)
        .deleteTask(groupId, projectId, taskId);
    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          context.go('/groups/$groupId/projects/$projectId');
          showAppSnackBar(context, 'Tarea eliminada');
        },
        onError: (error) =>
            showAppSnackBar(context, error.message, isError: true),
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
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Widget que muestra quién tiene asignada la tarea con nombre real
class _AssigneeDisplay extends ConsumerWidget {
  final String assigneeId;

  const _AssigneeDisplay({required this.assigneeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(userNameProvider(assigneeId));

    return nameAsync.when(
      data: (name) => _AssigneeDisplayContent(
        name: name ?? _shortUid(assigneeId),
        shortUid: _shortUid(assigneeId),
      ),
      loading: () => _AssigneeDisplayContent(
        name: 'Cargando...',
        shortUid: _shortUid(assigneeId),
        isLoading: true,
      ),
      error: (_, __) => _AssigneeDisplayContent(
        name: _shortUid(assigneeId),
        shortUid: _shortUid(assigneeId),
      ),
    );
  }

  String _shortUid(String uid) {
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 8)}...';
  }
}

class _AssigneeDisplayContent extends StatelessWidget {
  final String name;
  final String shortUid;
  final bool isLoading;

  const _AssigneeDisplayContent({
    required this.name,
    required this.shortUid,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              shortUid.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Asignada a',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 100,
                    child: LinearProgressIndicator(),
                  )
                else
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
        ],
      ),
    );
  }
}
