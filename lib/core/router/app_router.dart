import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/groups/presentation/screens/groups_list_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/projects/presentation/screens/projects_list_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/offers/presentation/screens/offer_form_screen.dart';
import '../../features/fairness/presentation/screens/fairness_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

import '../../features/auth/application/auth_providers.dart';

/// Proveedor del router de la aplicación.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateChanges = ref.watch(authStateChangesProvider);
  final profileState = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authStateChanges.value;
      final profile = profileState.value;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/role-selection';

      // Sin usuario autenticado -> login
      if (user == null) {
        if (!isAuthRoute && location != '/') {
          return '/login';
        }
        return null;
      }

      // Usuario autenticado pero sin perfil -> role selection
      if (profile == null) {
        if (location != '/role-selection' && !isAuthRoute) {
          return '/role-selection';
        }
        return null;
      }

      // Usuario con perfil completo
      if (isAuthRoute) {
        return '/groups';
      }

      return null;
    },
    routes: [
      // Splash screen (mientras carga el perfil)
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Flujo de autenticación
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Área principal (requiere auth + perfil)
      GoRoute(
        path: '/groups',
        name: 'groups',
        builder: (context, state) => const GroupsListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createGroup',
            builder: (context, state) => const GroupDetailScreen(isCreating: true),
          ),
          GoRoute(
            path: ':groupId',
            name: 'groupDetail',
            builder: (context, state) => GroupDetailScreen(
              groupId: state.pathParameters['groupId']!,
            ),
            routes: [
              GoRoute(
                path: 'projects',
                name: 'groupProjects',
                builder: (context, state) => ProjectsListScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'createProject',
                    builder: (context, state) => ProjectDetailScreen(
                      groupId: state.pathParameters['groupId']!,
                      projectId: '',
                      isCreating: true,
                    ),
                  ),
                  GoRoute(
                    path: ':projectId',
                    name: 'projectDetail',
                    builder: (context, state) => ProjectDetailScreen(
                      groupId: state.pathParameters['groupId']!,
                      projectId: state.pathParameters['projectId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'tasks/:taskId',
                        name: 'taskDetail',
                        builder: (context, state) => TaskDetailScreen(
                          groupId: state.pathParameters['groupId']!,
                          projectId: state.pathParameters['projectId']!,
                          taskId: state.pathParameters['taskId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'fairness',
                        name: 'projectFairness',
                        builder: (context, state) => FairnessScreen(
                          groupId: state.pathParameters['groupId']!,
                          projectId: state.pathParameters['projectId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Ofertas (acceso directo desde notificaciones, etc.)
      GoRoute(
        path: '/offers/new',
        name: 'newOffer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OfferFormScreen(
            groupId: extra?['groupId'] as String,
            projectId: extra?['projectId'] as String,
            taskId: extra?['taskId'] as String,
          );
        },
      ),

      // Perfil
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error.toString()),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/groups'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Proveedor que expone los cambios de estado de autenticación.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});