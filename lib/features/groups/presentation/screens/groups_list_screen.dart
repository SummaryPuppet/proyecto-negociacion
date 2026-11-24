import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/groups/application/group_providers.dart';
import 'package:repartojusto/features/groups/data/group_repository.dart';
import 'package:repartojusto/features/groups/domain/app_group.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  bool _showingCreateDialog = false;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
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
      body: groupsAsync.when(
        data: (groups) => _buildList(context, groups),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorScreen(
          message: 'Error al cargar grupos: $error',
          onRetry: () => ref.invalidate(myGroupsProvider),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AppGroup> groups) {
    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: 'No tienes grupos aún',
        message: 'Crea un grupo nuevo o únete a uno existente con un código de invitación.',
        actionLabel: 'Crear grupo',
        onAction: () => _showCreateDialog(context),
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
                        if (group.isTeacher(ref.read(authStateChangesProvider).value?.uid ?? ''))
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
                          '${group.memberIds.length} miembros',
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

  void _showCreateDialog(BuildContext context) {
    if (_showingCreateDialog) return;
    _showingCreateDialog = true;

    final nameController = TextEditingController();
    final periodController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Crear grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo',
                hintText: 'ej. Programación Avanzada',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: periodController,
              decoration: const InputDecoration(
                labelText: 'Periodo / Curso',
                hintText: 'ej. 2025-2026 Q1',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _showingCreateDialog = false;
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || periodController.text.trim().isEmpty) {
                showAppSnackBar(context, 'Completa ambos campos', isError: true);
                return;
              }
              Navigator.pop(context);
              _showingCreateDialog = false;

              final currentUid = ref.read(authRepositoryProvider).currentUser?.uid ??
                  ref.read(authStateChangesProvider).value?.uid;
              if (currentUid == null) {
                showAppSnackBar(context, 'Sesión no válida', isError: true);
                return;
              }

              final result = await ref.read(groupRepositoryProvider).createGroup(
                    name: nameController.text.trim(),
                    period: periodController.text.trim(),
                    teacherId: currentUid,
                  );

              if (context.mounted) {
                result.fold(
                  onSuccess: (group) {
                    showAppSnackBar(context, 'Grupo creado: ${group.name}');
                    // Añadir groupId al usuario
                    ref.read(userRepositoryProvider).addGroupId(
                          currentUid,
                          group.id,
                        );
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
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(context);

              final currentUid = ref.read(authRepositoryProvider).currentUser?.uid ??
                  ref.read(authStateChangesProvider).value?.uid;
              if (currentUid == null) {
                showAppSnackBar(context, 'Sesión no válida', isError: true);
                return;
              }

              final result = await ref.read(groupRepositoryProvider).joinByCode(
                    code: code,
                    userId: currentUid,
                  );

              if (context.mounted) {
                result.fold(
                  onSuccess: (group) {
                    showAppSnackBar(context, 'Te uniste a: ${group.name}');
                    // Añadir groupId al usuario
                    ref.read(userRepositoryProvider).addGroupId(
                          currentUid,
                          group.id,
                        );
                  },
                  onError: (error) => showAppSnackBar(context, error.message, isError: true),
                );
              }
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }
}