import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/auth/data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authRepositoryProvider).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        onSuccess: (credential) {
          // La redirección la maneja el router
        },
        onError: (error) {
          showAppSnackBar(context, error.message, isError: true);
        },
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    final result = await ref.read(authRepositoryProvider).signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        onSuccess: (credential) {
          // Router maneja la redirección
        },
        onError: (error) {
          if (error.code == '10' || error.message.contains('SHA-1')) {
            showAppSnackBar(
              context,
              'Google Sign-In requiere registrar la SHA-1 en Firebase Console. '
              'Mientras tanto usa email/contraseña.',
              isError: true,
              duration: const Duration(seconds: 6),
            );
          } else if (error.message.contains('popup')) {
            showAppSnackBar(
              context,
              'Permite las ventanas emergentes para Google Sign-In.',
              isError: true,
            );
          } else {
            showAppSnackBar(context, error.message, isError: true);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Título
                Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'RepartoJusto',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Negocia y distribuye tareas en grupo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'tucorreo@ejemplo.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Introduce tu email';
                          }
                          if (!value.contains('@')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Introduce tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showResetPasswordDialog(context),
                          child: const Text('¿Olvidaste la contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LoadingButton(
                        onPressed: _submit,
                        isLoading: _isLoading,
                        child: const Text('Iniciar sesión'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Google Sign-In
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
                  ),
                  label: const Text('Continuar con Google'),
                ),

                const SizedBox(height: 16),

                // Registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Regístrate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'tucorreo@ejemplo.com',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!isValidEmail(controller.text.trim())) {
                showAppSnackBar(context, 'Email inválido', isError: true);
                return;
              }
              final result = await ref.read(authRepositoryProvider).sendPasswordReset(controller.text.trim());
              if (context.mounted) {
                result.fold(
                  onSuccess: (_) => showAppSnackBar(context, 'Email de recuperación enviado'),
                  onError: (error) => showAppSnackBar(context, error.message, isError: true),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}