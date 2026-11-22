import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/utils.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    this.groupId,
    this.isCreating = false,
  });

  final String? groupId;
  final bool isCreating;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
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
    // TODO: Conectar con stream del grupo
    final group = _MockGroup(
      id: widget.groupId!,
      name: 'Programación Avanzada',
      period: '2025-2026 Q1',
      joinCode: 'PRG2025',
      teacherName: 'Prof. García',
      leaderName: 'Ana López',
      members: [
        _MockMember('1', 'Ana López', 'ana@email.com', true, false),
        _MockMember('2', 'Carlos Ruiz', 'carlos@email.com', false, false),
        _MockMember('3', 'María Torres', 'maria@email.com', false, false),
        _MockMember('4', 'Juan Pérez', 'juan@email.com', false, false),
        _MockMember('5', 'Laura Martín', 'laura@email.com', false, false),
      ],
      projects: [
        _MockProject('p1', 'Proyecto Final', 'En negociación', 3),
        _MockProject('p2', 'Entrega Parcial 1', 'Asignado', 2),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              // TODO: Copiar código
              showAppSnackBar(context, 'Código copiado: ${group.joinCode}');
            },
            tooltip: 'Copiar código',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Editar grupo
              } else if (value == 'delete') {
                // TODO: Eliminar grupo
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
      body: ListView(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        group.joinCode,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 2,
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
                      'Docente: ${group.teacherName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (group.leaderName != null) ...[
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
                        'Jefe de grupo: ${group.leaderName}',
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
          SectionDivider(label: 'Miembros (${group.members.length})'),
          const SizedBox(height: 8),
          ...group.members.map((m) => _MemberTile(member: m)),

          const SizedBox(height: 16),

          // Proyectos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionDivider(label: 'Proyectos (${group.projects.length})'),
              TextButton.icon(
                onPressed: () => context.go('/groups/${group.id}/projects/create'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...group.projects.map((p) => _ProjectTile(project: p, groupId: group.id)),
          if (group.projects.isEmpty)
            EmptyState(
              icon: Icons.assignment_outlined,
              title: 'Sin proyectos',
              message: 'Crea el primer proyecto para empezar a negociar tareas.',
              actionLabel: 'Crear proyecto',
              onAction: () => context.go('/groups/${group.id}/projects/create'),
            ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/groups');
      showAppSnackBar(context, 'Grupo creado (simulado)');
    }
  }
}

class _MockGroup {
  final String id;
  final String name;
  final String period;
  final String joinCode;
  final String teacherName;
  final String? leaderName;
  final List<_MockMember> members;
  final List<_MockProject> projects;

  _MockGroup({
    required this.id,
    required this.name,
    required this.period,
    required this.joinCode,
    required this.teacherName,
    this.leaderName,
    required this.members,
    required this.projects,
  });
}

class _MockMember {
  final String id;
  final String name;
  final String email;
  final bool isLeader;
  final bool isTeacher;

  _MockMember(this.id, this.name, this.email, this.isLeader, this.isTeacher);
}

class _MockProject {
  final String id;
  final String name;
  final String status;
  final int taskCount;

  _MockProject(this.id, this.name, this.status, this.taskCount);
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final _MockMember member;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(name: member.name, radius: 22),
      title: Text(member.name),
      subtitle: Text(member.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.isTeacher)
            StatusChip(label: 'Docente', status: StatusType.info),
          if (member.isLeader)
            StatusChip(label: 'Jefe', status: StatusType.success),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.groupId});

  final _MockProject project;
  final String groupId;

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
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: Theme.of(context).colorScheme.secondary,
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
                    Text(
                      '${project.taskCount} tareas',
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