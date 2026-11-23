import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/projects/application/project_providers.dart';
import 'package:repartojusto/features/projects/domain/project.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider(groupId));
    final isTeacher = ref.watch(isProjectTeacherProvider((groupId: groupId, projectId: '')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.go('/groups/$groupId/projects/create'),
              tooltip: 'Crear proyecto',
            ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) => _buildList(context, ref, projects, isTeacher),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorScreen(
          message: 'Error al cargar proyectos: $error',
          onRetry: () => ref.invalidate(projectsProvider(groupId)),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Project> projects, bool isTeacher) {
    if (projects.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Sin proyectos',
        message: isTeacher
            ? 'Crea el primer proyecto para empezar a negociar tareas.'
            : 'El docente aún no ha creado ningún proyecto en este grupo.',
        actionLabel: isTeacher ? 'Crear proyecto' : null,
        onAction: isTeacher ? () => context.go('/groups/$groupId/projects/create') : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectCard(project: project, groupId: groupId);
      },
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project, required this.groupId});

  final Project project;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher = ref.watch(isProjectTeacherProvider((groupId: groupId, projectId: project.id)));

    return AppCard(
      onTap: () => context.go('/groups/$groupId/projects/${project.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusChip(
                          label: _statusLabel(project.status),
                          status: _statusType(project.status),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Entrega: ${_formatDate(project.deliveryDeadline)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isTeacher)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(context, ref, value, project),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    const PopupMenuItem(value: 'start', child: Text('Iniciar negociación')),
                    const PopupMenuItem(value: 'close', child: Text('Cerrar proyecto')),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.assignment_outlined,
                label: '${project.totalPoints} pts totales',
                color: Colors.amber.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, Project project) {
    switch (action) {
      case 'edit':
        // TODO: Implementar edición
        showAppSnackBar(context, 'Editar proyecto (pendiente)');
        break;
      case 'delete':
        _confirmDelete(context, ref, project);
        break;
      case 'start':
        _confirmStartNegotiation(context, ref, project);
        break;
      case 'close':
        _confirmCloseProject(context, ref, project);
        break;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar proyecto',
      message: 'Se eliminarán todas las tareas y ofertas. ¿Seguro?',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(projectRepositoryProvider).deleteProject(groupId, project.id);
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => showAppSnackBar(context, 'Proyecto eliminado'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _confirmStartNegotiation(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Iniciar negociación',
      message: 'Los estudiantes podrán ofertar en las tareas. ¿Continuar?',
      confirmText: 'Iniciar',
    );
    if (!confirmed) return;

    final result = await ref.read(projectRepositoryProvider).setStatus(
          groupId: groupId,
          projectId: project.id,
          status: 'negotiating',
        );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => showAppSnackBar(context, 'Negociación iniciada'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _confirmCloseProject(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cerrar proyecto',
      message: 'No se podrán hacer más cambios. ¿Seguro?',
      confirmText: 'Cerrar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(projectRepositoryProvider).setStatus(
          groupId: groupId,
          projectId: project.id,
          status: 'closed',
        );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => showAppSnackBar(context, 'Proyecto cerrado'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'negotiating':
        return 'En negociación';
      case 'assigned':
        return 'Asignado';
      case 'closed':
        return 'Cerrado';
      case 'draft':
        return 'Borrador';
      default:
        return status;
    }
  }

  StatusType _statusType(String status) {
    switch (status) {
      case 'negotiating':
        return StatusType.warning;
      case 'assigned':
        return StatusType.info;
      case 'closed':
        return StatusType.success;
      case 'draft':
        return StatusType.neutral;
      default:
        return StatusType.neutral;
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}