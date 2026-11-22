import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header del perfil
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                UserAvatar(
                  photoUrl: user?.photoURL,
                  name: user?.displayName ?? 'Usuario',
                  radius: 50,
                  fontSize: 24,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Sin nombre',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Sin email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Estudiante', // TODO: Rol real
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Configuración
          SectionDivider(label: 'Configuración'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Editar perfil',
            subtitle: 'Nombre, foto, biografía',
            onTap: () => _showEditProfileDialog(context),
          ),

          _SettingsTile(
            icon: Icons.code_outlined,
            title: 'Skills y disponibilidad',
            subtitle: 'Tecnologías que dominas y horarios',
            onTap: () => showAppSnackBar(context, 'Skills (pendiente)'),
          ),

          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Preferencias de avisos',
            onTap: () => showAppSnackBar(context, 'Notificaciones (pendiente)'),
          ),

          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Tema',
            subtitle: 'Claro, oscuro o sistema',
            trailing: _ThemeSelector(),
            onTap: () {},
          ),

          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Idioma',
            subtitle: 'Español (predeterminado)',
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // Cuenta
          SectionDivider(label: 'Cuenta'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Cambiar contraseña',
            subtitle: 'Actualizar credenciales',
            onTap: () => _showChangePasswordDialog(context),
          ),

          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Eliminar cuenta',
            subtitle: 'Eliminar todos tus datos permanentemente',
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 16),

          // Cerrar sesión
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Versión
          Center(
            child: Text(
              'RepartoJusto v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Actualizar perfil
              showAppSnackBar(context, 'Perfil actualizado (simulado)');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar nueva'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Cambiar contraseña
              showAppSnackBar(context, 'Contraseña cambiada (simulado)');
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showConfirmDialog(
      context,
      title: 'Eliminar cuenta',
      message: 'Esta acción es irreversible. Se eliminarán todos tus datos, grupos, ofertas y comentarios. ¿Estás seguro?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed) {
        // TODO: Eliminar cuenta
        showAppSnackBar(context, 'Cuenta eliminada (simulado)');
      }
    });
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isDestructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null)
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return PopupMenuButton<ThemeMode>(
      initialValue: ThemeMode.system,
      onSelected: (mode) {
        // TODO: Guardar preferencia de tema
        showAppSnackBar(context, 'Tema cambiado a: ${mode.name}');
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
        const PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
        const PopupMenuItem(value: ThemeMode.system, child: Text('Sistema')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              brightness == Brightness.dark ? 'Oscuro' : 'Claro',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}