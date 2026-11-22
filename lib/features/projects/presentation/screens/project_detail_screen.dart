import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/utils.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.groupId,
    this.projectId,
    this.isCreating = false,
  });

  final String groupId;
  final String? projectId;
  final bool isCreating;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _negotiationDeadlineController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _deadlineController.dispose();
    _negotiationDeadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCreating) {
      return _buildCreateForm(context);
    }
    return _buildDetail(context);
  }

  Widget _buildCreateForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear proyecto')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Nuevo proyecto',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Define el proyecto y sus plazos. Luego podrás añadir tareas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Título del proyecto',
                    hintText: 'ej. Proyecto Final de Curso',
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles del trabajo...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _negotiationDeadlineController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Fin negociación',
                          prefixIcon: Icon(Icons.gavel_outlined),
                        ),
                        onTap: () => _pickDate(context, _negotiationDeadlineController),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deadlineController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Fecha entrega',
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                        onTap: () => _pickDate(context, _deadlineController),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                LoadingButton(
                  onPressed: _createProject,
                  isLoading: _isLoading,
                  child: const Text('Crear proyecto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    // TODO: Conectar con stream del proyecto
    final project = _MockProject(
      id: widget.projectId ?? '',
      name: 'Proyecto Final',
      description: 'Desarrollo de una aplicación completa con Flutter y Firebase.',
      deadline: '15/12/2025',
      negotiationDeadline: '01/12/2025',
      totalPoints: 120,
      status: 'negotiating',
      tasks: [
        _MockTask('t1', 'Diseño UI/UX', 30, 10, 'assigned', 'Ana López'),
        _MockTask('t2', 'Backend API', 40, 15, 'negotiating', null),
        _MockTask('t3', 'Frontend Flutter', 35, 12, 'open', null),
        _MockTask('t4', 'Testing y Docs', 15, 5, 'open', null),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/groups/${widget.groupId}/projects/${widget.projectId ?? ''}/fairness'),
            tooltip: 'Equidad',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Editar
              } else if (value == 'close') {
                // TODO: Cerrar negociación
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'close', child: Text('Cerrar negociación')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header con progreso
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusChip(
                              label: _statusLabel(project.status),
                              status: _statusType(project.status),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${project.totalPoints} pts totales',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    CircularProgressWithPercent(
                      progress: _calcProgress(project),
                      size: 56,
                      strokeWidth: 5,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.gavel_outlined,
                      label: 'Fin negociación: ${project.negotiationDeadline}',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.event_outlined,
                      label: 'Entrega: ${project.deadline}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tareas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionDivider(label: 'Tareas (${project.tasks.length})'),
              TextButton.icon(
                onPressed: () {
                  // TODO: Crear tarea
                  showAppSnackBar(context, 'Crear tarea (pendiente)');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva tarea'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...project.tasks.map((t) => _TaskTile(
            task: t,
            groupId: widget.groupId,
            projectId: widget.projectId ?? '',
          )),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      controller.text = AppFormatters.formatDate(date);
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/groups/${widget.groupId}/projects');
      showAppSnackBar(context, 'Proyecto creado (simulado)');
    }
  }

  double _calcProgress(_MockProject p) {
    final assigned = p.tasks.where((t) => t.status == 'assigned').length;
    return p.tasks.isEmpty ? 0 : assigned / p.tasks.length;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'negotiating':
        return 'En negociación';
      case 'assigned':
        return 'Asignado';
      case 'closed':
        return 'Cerrado';
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
      default:
        return StatusType.neutral;
    }
  }
}

class _MockProject {
  final String id;
  final String name;
  final String description;
  final String deadline;
  final String negotiationDeadline;
  final int totalPoints;
  final String status;
  final List<_MockTask> tasks;

  _MockProject({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    required this.negotiationDeadline,
    required this.totalPoints,
    required this.status,
    required this.tasks,
  });
}

class _MockTask {
  final String id;
  final String title;
  final int weight;
  final int estHours;
  final String status;
  final String? assignee;

  _MockTask(this.id, this.title, this.weight, this.estHours, this.status, this.assignee);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.groupId,
    required this.projectId,
  });

  final _MockTask task;
  final String groupId;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(
        '/groups/$groupId/projects/$projectId/tasks/${task.id}',
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _statusIcon(task.status),
              color: _statusColor(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: _statusLabel(task.status),
                      status: _statusType(task.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(icon: Icons.star_outlined, value: '${task.weight} pts', color: Colors.amber.shade700),
                    const SizedBox(width: 16),
                    _MiniStat(icon: Icons.access_time_outlined, value: '${task.estHours} h', color: Theme.of(context).colorScheme.primary),
                    if (task.assignee != null) ...[
                      const SizedBox(width: 16),
                      _MiniStat(icon: Icons.person_outline, value: task.assignee!, color: context.success),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case 'assigned':
        return context.success;
      case 'negotiating':
        return context.warning;
      case 'open':
        return context.info;
      default:
        return context.outline;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.check_circle_outline;
      case 'negotiating':
        return Icons.gavel_outlined;
      case 'open':
        return Icons.add_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Asignada';
      case 'negotiating':
        return 'Negociando';
      case 'open':
        return 'Abierta';
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
      default:
        return StatusType.neutral;
    }
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}