import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/auth/domain/app_user.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final authAsync = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'RepartoJusto',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _loadingMessage(authAsync, profileAsync),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _loadingMessage(
    AsyncValue<firebase_auth.User?> authAsync,
    AsyncValue<AppUser?> profileAsync,
  ) {
    if (authAsync.isLoading) return 'Iniciando sesión...';
    if (authAsync.value == null) return 'Sin sesión';
    if (profileAsync.isLoading) return 'Cargando perfil...';
    return 'Preparando...';
  }
}