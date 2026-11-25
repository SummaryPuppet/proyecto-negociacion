import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';

/// Punto de entrada de la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar notificaciones locales (opcional, se inicializa al usarlas)
  // await _initLocalNotifications();

  runApp(const ProviderScope(child: RepartoJustoApp()));
}

/// Aplicación principal con Riverpod, go_router y temas.
class RepartoJustoApp extends ConsumerWidget {
  const RepartoJustoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(themeModeProvider);

    // Mientras carga el tema, usar system como fallback
    final themeMode = themeModeAsync.asData?.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'RepartoJusto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      locale: const Locale('es', 'ES'), // Forzar español
      builder: (context, child) {
        // Wrapper global para MediaQuery (tamaño de texto, etc.)
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3)),
          ),
          child: child!,
        );
      },
    );
  }
}