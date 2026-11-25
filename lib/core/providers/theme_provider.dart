import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave para guardar la preferencia de tema en SharedPreferences
const _themeModeKey = 'theme_mode';

/// Notifier que gestiona el ThemeMode y lo persiste en SharedPreferences
class ThemeModeNotifier {
  ThemeModeNotifier() : _themeMode = ThemeMode.system, _controller = StreamController<ThemeMode>.broadcast() {
    _loadThemeMode();
  }

  ThemeMode _themeMode;
  final StreamController<ThemeMode> _controller;

  ThemeMode get current => _themeMode;

  Stream<ThemeMode> get stream => _controller.stream;

  /// Carga el ThemeMode guardado desde SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeModeKey);
      if (themeIndex != null && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
        _controller.add(_themeMode);
      }
    } catch (_) {
      // Si falla la carga, mantenemos el valor por defecto (system)
    }
  }

  /// Cambia el ThemeMode y lo guarda en SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _controller.add(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (_) {
      // Si falla el guardado, el estado en memoria ya cambió
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Proveedor del notifier del tema
final themeModeNotifierProvider = Provider<ThemeModeNotifier>((ref) {
  final notifier = ThemeModeNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Proveedor reactivo del ThemeMode actual (StreamProvider)
final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  final notifier = ref.watch(themeModeNotifierProvider);
  // Emitir valor inicial y luego escuchar cambios
  return Stream<ThemeMode>.multi((controller) {
    controller.add(notifier.current);
    final subscription = notifier.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
});