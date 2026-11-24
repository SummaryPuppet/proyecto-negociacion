import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/groups/application/group_providers.dart';
import 'package:repartojusto/features/groups/data/group_repository.dart';
import 'package:repartojusto/features/groups/domain/app_group.dart';
import 'package:repartojusto/features/projects/application/project_providers.dart';
import 'package:repartojusto/features/projects/domain/project.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({
    super.key,
    this.groupId,
    this.isCreating = false,
  });

  final String? groupId;
  final bool isCreating;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _periodController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _periodController.dispose();
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
      appBar: AppBar(title: const Text('Crear grupo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nuevo grupo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa los datos para crear el grupo. Serás el docente responsable.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                    hintText: 'ej. Programación Avanzada',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Introduce un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _periodController,
                  decoration: const InputDecoration(
                    labelText: 'Periodo / Curso',
                    hintText: 'ej. 2025-2026 Q1',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Introduce el periodo';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                LoadingButton(
                  onPressed: _createGroup,
                  isLoading: _isLoading,
                  child: const Text('Crear grupo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final groupId = widget.groupId!;
    final groupAsync = ref.watch(groupProvider(groupId));
    final currentUserId = ref.read(authStateChangesProvider).value?.uid ?? '';
    final isTeacher = ref.watch(isGroupTeacherProvider(groupId));
    final isLeader = ref.watch(isGroupLeaderProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (g) => Text(g?.name ?? 'Cargando...'),
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          if (isTeacher)
            PopupMenuButton<String>(
              onSelected: (value) => _handleTeacherAction(context, value, groupId, currentUserId),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar nombre/periodo')),
                const PopupMenuItem(value: 'regenerate', child: Text('Regenerar código')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar grupo')),
              ],
            ),
          if (!isTeacher)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _leaveGroup(context, groupId),
              tooltip: 'Salir del grupo',
            ),
        ],
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return ErrorScreen(
              message: 'Grupo no encontrado',
              onRetry: () => ref.invalidate(groupProvider(groupId)),
            );
          }
          return _buildGroupContent(context, group, currentUserId, isTeacher, isLeader);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorScreen(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(groupProvider(groupId)),
        ),
      ),
    );
  }

  Widget _buildGroupContent(
    BuildContext context,
    AppGroup group,
    String currentUserId,
    bool isTeacher,
    bool isLeader,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info del grupo
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Código de invitación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: group.joinCode));
                      showAppSnackBar(context, 'Código copiado al portapapeles: ${group.joinCode}');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.joinCode,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.period,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.school_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tú eres ${isTeacher ? 'el docente' : 'estudiante'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (group.hasLeader) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 18,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group.isLeader(currentUserId)
                          ? 'Eres el jefe de grupo'
                          : 'Jefe: (cargar nombre)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Miembros
        SectionDivider(label: 'Miembros (${group.memberIds.length})'),
        const SizedBox(height: 8),
        ..._buildMembersList(context, group, currentUserId, isTeacher, isLeader),

        const SizedBox(height: 16),

        // Proyectos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionDivider(label: 'Proyectos'),
            TextButton.icon(
              onPressed: () => context.go('/groups/${group.id}/projects'),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Ver proyectos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ProjectsPreview(groupId: group.id, isTeacher: isTeacher),
      ],
    );
  }

  List<Widget> _buildMembersList(
    BuildContext context,
    AppGroup group,
    String currentUserId,
    bool isTeacher,
    bool isLeader,
  ) {
    // TODO: Cargar nombres reales de usuarios desde users collection
    // Por ahora mostramos solo IDs con avatar
    return group.memberIds.map((memberId) {
      final isSelf = memberId == currentUserId;
      final isMemberTeacher = group.isTeacher(memberId);
      final isMemberLeader = group.isLeader(memberId);

      return AppCard(
        padding: const EdgeInsets.all(12),
        child: ListTile(
          leading: UserAvatar(name: memberId.substring(0, 8), radius: 22),
          title: Text(isSelf ? '$memberId (tú)' : memberId.substring(0, 20)),
          subtitle: Text(isSelf ? 'Tu cuenta' : 'Miembro'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMemberTeacher)
                StatusChip(label: 'Docente', status: StatusType.info),
              if (isMemberLeader)
                StatusChip(label: 'Jefe', status: StatusType.success),
              if (isTeacher && !isSelf && !isMemberLeader)
                TextButton(
                  onPressed: () => _makeLeader(context, group.id, memberId),
                  child: const Text('Nombrar jefe'),
                ),
              if (isTeacher && !isSelf)
                TextButton(
                  onPressed: () => _removeMember(context, group.id, memberId),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Expulsar'),
                ),
            ],
          ),
        ));
      }).toList();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final currentUid = ref.read(authRepositoryProvider).currentUser?.uid ??
        ref.read(authStateChangesProvider).value?.uid;
    if (currentUid == null) {
      showAppSnackBar(context, 'Sesión no válida', isError: true);
      return;
    }

    final result = await ref.read(groupRepositoryProvider).createGroup(
          name: _nameController.text.trim(),
          period: _periodController.text.trim(),
          teacherId: currentUid,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        onSuccess: (group) {
          ref.read(userRepositoryProvider).addGroupId(
                currentUid,
                group.id,
              );
          context.go('/groups');
          showAppSnackBar(context, 'Grupo creado: ${group.name}');
        },
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _handleTeacherAction(BuildContext context, String action, String groupId, String currentUserId) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, groupId);
        break;
      case 'regenerate':
        _regenerateCode(context, groupId);
        break;
      case 'delete':
        _confirmDelete(context, groupId);
        break;
    }
  }

  void _showEditDialog(BuildContext context, String groupId) {
    final group = ref.read(groupSyncProvider(groupId));
    if (group == null) return;

    final nameController = TextEditingController(text: group.name);
    final periodController = TextEditingController(text: group.period);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: periodController,
              decoration: const InputDecoration(labelText: 'Periodo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implementar actualización
              showAppSnackBar(context, 'Editar grupo (pendiente)');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _regenerateCode(BuildContext context, String groupId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Regenerar código',
      message: 'Se generará un nuevo código de invitación. El anterior dejará de funcionar. ¿Continuar?',
      confirmText: 'Regenerar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(groupRepositoryProvider).regenerateJoinCode(groupId);
    if (context.mounted) {
      result.fold(
        onSuccess: (newCode) => showAppSnackBar(context, 'Nuevo código: $newCode'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _confirmDelete(BuildContext context, String groupId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar grupo',
      message: 'Esta acción es irreversible. Se eliminarán todos los proyectos, tareas y ofertas del grupo. ¿Seguro?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(groupRepositoryProvider).deleteGroup(groupId);
    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          context.go('/groups');
          showAppSnackBar(context, 'Grupo eliminado');
        },
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _makeLeader(BuildContext context, String groupId, String memberId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Nombrar jefe de grupo',
      message: 'El nuevo jefe podrá arbitrar ofertas y desempatar votaciones. ¿Continuar?',
      confirmText: 'Nombrar',
    );
    if (!confirmed) return;

    final result = await ref.read(groupRepositoryProvider).setLeader(
          groupId: groupId,
          newLeaderId: memberId,
        );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => showAppSnackBar(context, 'Jefe actualizado'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _removeMember(BuildContext context, String groupId, String memberId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Expulsar miembro',
      message: 'Se eliminará del grupo y perderá acceso a todos los proyectos. ¿Seguro?',
      confirmText: 'Expulsar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(groupRepositoryProvider).removeMember(
          groupId: groupId,
          memberId: memberId,
        );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) => showAppSnackBar(context, 'Miembro expulsado'),
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }

  void _leaveGroup(BuildContext context, String groupId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Salir del grupo',
      message: 'Perderás acceso a todos los proyectos y tareas de este grupo. ¿Seguro?',
      confirmText: 'Salir',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref.read(groupRepositoryProvider).leaveGroup(
          groupId: groupId,
          userId: ref.read(authStateChangesProvider).value!.uid,
        );
    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          context.go('/groups');
          showAppSnackBar(context, 'Has salido del grupo');
        },
        onError: (error) => showAppSnackBar(context, error.message, isError: true),
      );
    }
  }
}

class _ProjectsPreview extends ConsumerWidget {
  const _ProjectsPreview({required this.groupId, required this.isTeacher});

  final String groupId;
  final bool isTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider(groupId));

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return EmptyState(
            icon: Icons.assignment_outlined,
            title: 'Sin proyectos',
            message: 'Crea el primer proyecto para empezar a negociar tareas.',
            actionLabel: isTeacher ? 'Crear proyecto' : null,
            onAction: isTeacher
                ? () => context.go('/groups/$groupId/projects/create')
                : null,
          );
        }
        return Column(
          children: projects
              .take(3)
              .map((p) => _ProjectTile(project: p, groupId: groupId, isTeacher: isTeacher))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorScreen(
        message: 'Error al cargar proyectos: $error',
        onRetry: () => ref.invalidate(projectsProvider(groupId)),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.groupId, required this.isTeacher});

  final Project project;
  final String groupId;
  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/groups/$groupId/projects/${project.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    Text(
                      '${project.totalPoints} pts',
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
              onSelected: (value) => _handleAction(context, value, project),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'start', child: Text('Iniciar negociación')),
                const PopupMenuItem(value: 'close', child: Text('Cerrar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            )
          else
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, Project project) {
    switch (action) {
      case 'edit':
        showAppSnackBar(context, 'Editar proyecto (pendiente)');
        break;
      case 'start':
        showAppSnackBar(context, 'Iniciar negociación (pendiente)');
        break;
      case 'close':
        showAppSnackBar(context, 'Cerrar proyecto (pendiente)');
        break;
      case 'delete':
        showAppSnackBar(context, 'Eliminar proyecto (pendiente)');
        break;
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
}