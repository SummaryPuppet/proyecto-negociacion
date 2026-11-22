import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/common_widgets.dart';

class ProjectsListScreen extends StatelessWidget {
  const ProjectsListScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/groups/$groupId/projects/create'),
            tooltip: 'Crear proyecto',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // TODO: Conectar con stream de proyectos del grupo
    final projects = <_MockProject>[
      _MockProject('1', 'Proyecto Final', 'En negociación', '15/12/2025', 4, 120),
      _MockProject('2', 'Entrega Parcial 1', 'Asignado', '01/11/2025', 3, 80),
      _MockProject('3', 'Propuesta de Tema', 'Cerrado', '15/10/2025', 1, 20),
    ];

    if (projects.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Sin proyectos',
        message: 'El docente aún no ha creado ningún proyecto en este grupo.',
        actionLabel: 'Crear proyecto',
        onAction: () => context.go('/groups/$groupId/projects/create'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];
        return _ProjectCard(project: p, groupId: groupId);
      },
    );
  }
}

class _MockProject {
  final String id;
  final String name;
  final String status;
  final String deadline;
  final int taskCount;
  final int totalPoints;

  _MockProject(this.id, this.name, this.status, this.deadline, this.taskCount, this.totalPoints);
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.groupId});

  final _MockProject project;
  final String groupId;

  @override
  Widget build(BuildContext context) {
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
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusChip(
                          label: project.status,
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
                          'Entrega: ${project.deadline}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.assignment_outlined,
                label: '${project.taskCount} tareas',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.star_outlined,
                label: '${project.totalPoints} pts',
                color: Colors.amber.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  StatusType _statusType(String status) {
    switch (status) {
      case 'En negociación':
        return StatusType.warning;
      case 'Asignado':
        return StatusType.info;
      case 'Cerrado':
        return StatusType.success;
      default:
        return StatusType.neutral;
    }
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
        color: color.withOpacity(0.1),
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