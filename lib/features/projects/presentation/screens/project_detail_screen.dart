import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:repartojusto/core/theme/app_theme.dart';
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/projects/application/project_providers.dart';
import 'package:repartojusto/features/projects/data/project_repository.dart';
import 'package:repartojusto/features/projects/domain/project.dart';
import 'package:repartojusto/features/tasks/application/task_providers.dart';
import 'package:repartojusto/features/tasks/data/task_repository.dart';
import 'package:repartojusto/features/tasks/domain/task.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
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
                const SizedBox(height: 32),
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
    final params = (groupId: widget.groupId, projectId: widget.projectId ?? '');
    final projectAsync = ref.watch(projectProvider(params));
    final tasksAsync = ref.watch(tasksProvider(params));
    final isTeacher = ref.watch(isProjectTeacherProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: projectAsync.when(
          data: (p) => Text(p?.title ?? 'Cargando...'),
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go(
              '/groups/${widget.groupId}/projects/${widget.projectId ?? ''}/fairness',
            ),
            tooltip: 'Equidad',
          ),
          if (isTeacher)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, projectAsync.value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'start', child: Text('Iniciar negociación')),
                const PopupMenuItem(value: 'close', child: Text('Cerrar negociación')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar proyecto')),
              ],
            ),
        ],
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return ErrorScreen(
              message: 'Proyecto no encontrado',
              onRetry: () => ref.invalidate(projectProvider(params)),
            );
          }
          return _buildProjectContent(context, project, tasksAsync, isTeacher);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorScreen(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(projectProvider(params)),
        ),
      ),
    );
  }

  Widget _buildProjectContent(
    BuildContext context,
    Project project,
    AsyncValue<List<Task>> tasksAsync,
    bool isTeacher,
  ) {
    return ListView(
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
                  Expanded(
                    child: Column(
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
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            project.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  CircularProgressWithPercent(
                    progress: _calcProgress(tasksAsync.value ?? []),
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
                    label: 'Fin negociación: ${_formatDate(project.negotiationDeadline)}',
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.event_outlined,
                    label: 'Entrega: ${_formatDate(project.deliveryDeadline)}',
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
            Expanded(child: SectionDivider(label: 'Tareas (${tasksAsync.value?.length ?? 0})')),
            if (isTeacher)
              TextButton.icon(
                onPressed: () => _showCreateTaskDialog(context, project),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva tarea'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return EmptyState(
                icon: Icons.checklist_outlined,
                title: 'Sin tareas',
                message: isTeacher
                    ? 'Añade tareas con sus pesos para poder negociar.'
                    : 'El docente aún no ha definido las tareas.',
                actionLabel: isTeacher ? 'Nueva tarea' : null,
                onAction: isTeacher ? () => _showCreateTaskDialog(context, project) : null,
              );
            }
            return Column(
              children: tasks.map((t) => _TaskTile(
                task: t,
                groupId: widget.groupId,
                projectId: project.id,
                isTeacher: isTeacher,
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorScreen(
            message: 'Error al cargar tareas: $error',
            onRetry: () => ref.invalidate(tasksProvider(
              (groupId: widget.groupId, projectId: project.id),
            )),
          ),
        ),
      ],
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

    // Verificar permisos: solo el docente del grupo puede crear proyectos
    final isTeacher = ref.read(isProjectTeacherProvider((groupId: widget.groupId, projectId: '')));
    if (!isTeacher) {
      showAppSnackBar(context, 'Solo el docente del grupo puede crear proyectos', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final negotiationDate = AppFormatters.parseDate(_negotiationDeadlineController.text);
    final deliveryDate = AppFormatters.parseDate(_deadlineController.text);
    if (negotiationDate == null || deliveryDate == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context, 'Fechas inválidas', isError: true);
      }
      return;
    }

    final result = await ref.read(projectRepositoryProvider).createProject(
          groupId: widget.groupId,
          title: _nameController.text.trim(),
          description: _descController.text.trim(),
          negotiationDeadline: negotiationDate.millisecondsSinceEpoch,
          deliveryDeadline: deliveryDate.millisecondsSinceEpoch,
          teacherId: ref.read(authStateChangesProvider).value!.uid,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        onSuccess: (project) {
          context.go('/groups/${widget.groupId}/projects');
          showAppSnackBar(context, 'Proyecto creado: ${project.title}');
        },
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _handleAction(BuildContext context, String action, Project? project) {
    if (project == null) return;
    switch (action) {
      case 'edit':
        showAppSnackBar(context, 'Editar proyecto (pendiente)');
        break;
      case 'start':
        _confirmStartNegotiation(context, project);
        break;
      case 'close':
        _confirmCloseProject(context, project);
        break;
      case 'delete':
        _confirmDelete(context, project);
        break;
    }
  }

  void _confirmStartNegotiation(BuildContext context, Project project) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Iniciar negociación',
      message: 'Los estudiantes podrán ofertar en las tareas. ¿Continuar?',
      confirmText: 'Iniciar',
    );
    if (!confirmed) return;

    final result = await ref.read(projectRepositoryProvider).setStatus(
          groupId: widget.groupId,
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

  void _confirmCloseProject(BuildContext context, Project project) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cerrar negociación',
      message: 'No se podrán hacer más cambios. ¿Seguro?',
      confirmText: 'Cerrar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(projectRepositoryProvider).setStatus(
          groupId: widget.groupId,
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

  void _confirmDelete(BuildContext context, Project project) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar proyecto',
      message: 'Se eliminarán todas las tareas y ofertas. ¿Seguro?',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(projectRepositoryProvider).deleteProject(widget.groupId, project.id);
    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          context.go('/groups/${widget.groupId}/projects');
          showAppSnackBar(context, 'Proyecto eliminado');
        },
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _showCreateTaskDialog(BuildContext context, Project project) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final weightController = TextEditingController();
    final hoursController = TextEditingController();
    final skillsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva tarea'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  hintText: 'ej. Diseño UI/UX',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Detalles de la tarea...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puntos',
                        hintText: 'ej. 40',
                        prefixIcon: Icon(Icons.star_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Horas est.',
                        hintText: 'ej. 12',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (separadas por coma)',
                  hintText: 'Flutter, Firebase, SQL',
                  prefixIcon: Icon(Icons.code_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final weight = int.tryParse(weightController.text.trim()) ?? 0;
              final hours = int.tryParse(hoursController.text.trim()) ?? 0;
              final skills = skillsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              if (title.isEmpty || weight <= 0 || hours <= 0) {
                showAppSnackBar(context, 'Completa título, puntos y horas', isError: true);
                return;
              }

              Navigator.pop(context);

              final result = await ref.read(taskRepositoryProvider).createTask(
                    groupId: widget.groupId,
                    projectId: project.id,
                    title: title,
                    description: descController.text.trim(),
                    weight: weight,
                    estHours: hours,
                    skills: skills,
                  );

              if (context.mounted) {
                result.fold(
                  onSuccess: (task) async {
                    // Actualizar puntos totales del proyecto
                    final tasks = ref.read(tasksProvider(
                      (groupId: widget.groupId, projectId: project.id),
                    )).value ?? [];
                    final totalPoints = tasks.fold(0, (sum, t) => sum + t.weight) + task.weight;
                    await ref.read(projectRepositoryProvider).updateTotalPoints(
                          groupId: widget.groupId,
                          projectId: project.id,
                          totalPoints: totalPoints,
                        );
                    if (context.mounted) {
                      showAppSnackBar(context, 'Tarea creada: ${task.title}');
                    }
                  },
                  onError: (error) => showAppSnackBar(context, error.message, isError: true),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  double _calcProgress(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final assigned = tasks.where((t) => t.isAssigned || t.isDone).length;
    return assigned / tasks.length;
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy', 'es').format(date);
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

class _TaskTile extends ConsumerWidget {
  const _TaskTile({
    required this.task,
    required this.groupId,
    required this.projectId,
    required this.isTeacher,
  });

  final Task task;
  final String groupId;
  final String projectId;
  final bool isTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => context.go('/groups/$groupId/projects/$projectId/tasks/${task.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(context).withValues(alpha: 0.15),
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
                    if (task.assigneeId != null) ...[
                      const SizedBox(width: 16),
                      _assigneeName(ref, context),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isTeacher)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                if (task.isOpen)
                  const PopupMenuItem(value: 'assign', child: Text('Asignar manualmente')),
              ],
            )
          else
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
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
      case 'assign':
        showAppSnackBar(context, 'Asignar manualmente (pendiente de Fase 3)');
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

    final result = await ref.read(taskRepositoryProvider).deleteTask(groupId, projectId, task.id);
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => showAppSnackBar(context, 'Tarea eliminada'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  Widget _assigneeName(WidgetRef ref, BuildContext context) {
    final nameAsync = ref.watch(userNameProvider(task.assigneeId!));
    const successColor = Colors.green;
    return nameAsync.when(
      data: (name) => _MiniStat(
        icon: Icons.person_outline,
        value: name ?? task.assigneeId!.substring(0, 8),
        color: successColor,
      ),
      loading: () => _MiniStat(
        icon: Icons.person_outline,
        value: '...',
        color: successColor,
      ),
      error: (_, __) => _MiniStat(
        icon: Icons.person_outline,
        value: task.assigneeId!.substring(0, 8),
        color: successColor,
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