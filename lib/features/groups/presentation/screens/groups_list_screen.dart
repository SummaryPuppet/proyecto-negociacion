import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/utils.dart';

class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/groups/create'),
            tooltip: 'Crear grupo',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
            tooltip: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinDialog(context),
        icon: const Icon(Icons.login),
        label: const Text('Unirse a grupo'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // TODO: Conectar con stream de grupos del usuario
    final groups = <_MockGroup>[
      _MockGroup(
        id: '1',
        name: 'Programación Avanzada',
        period: '2025-2026 Q1',
        memberCount: 5,
        isTeacher: true,
        projectCount: 2,
      ),
      _MockGroup(
        id: '2',
        name: 'Bases de Datos',
        period: '2025-2026 Q1',
        memberCount: 4,
        isTeacher: false,
        projectCount: 1,
      ),
    ];

    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: 'No tienes grupos aún',
        message: 'Crea un grupo nuevo o únete a uno existente con un código de invitación.',
        actionLabel: 'Crear grupo',
        onAction: () => context.go('/groups/create'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return AppCard(
          onTap: () => context.go('/groups/${group.id}'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (group.isTeacher)
                          StatusChip(
                            label: 'Docente',
                            status: StatusType.info,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.period,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} miembros',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.assignment_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.projectCount} proyectos',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            hintText: 'ABC123',
            prefixIcon: Icon(Icons.vpn_key),
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Unirse al grupo con el código
              showAppSnackBar(context, 'Unirse a grupo: ${controller.text} (pendiente)');
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }
}

class _MockGroup {
  final String id;
  final String name;
  final String period;
  final int memberCount;
  final bool isTeacher;
  final int projectCount;

  _MockGroup({
    required this.id,
    required this.name,
    required this.period,
    required this.memberCount,
    required this.isTeacher,
    required this.projectCount,
  });
}