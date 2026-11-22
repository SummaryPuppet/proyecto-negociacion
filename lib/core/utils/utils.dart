import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formateadores de fecha y hora en español.
class AppFormatters {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'es');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');
  static final _timeFormat = DateFormat('HH:mm', 'es');
  static final _relativeFormat = DateFormat('dd MMM', 'es');

  /// Formatea una fecha como "dd/MM/yyyy".
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Formatea fecha y hora como "dd/MM/yyyy HH:mm".
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Formatea solo la hora como "HH:mm".
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Formatea fecha relativa como "15 nov".
  static String formatRelative(DateTime date) => _relativeFormat.format(date);

  /// Devuelve string relativo: "hace 5 min", "hace 2 horas", "ayer", etc.
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return formatRelative(date);
  }
}

/// Genera un código de invitación corto y legible.
String generateJoinCode({int length = 6}) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sin I, O, 0, 1
  final random = DateTime.now().millisecondsSinceEpoch;
  final buffer = StringBuffer();
  var seed = random;

  for (var i = 0; i < length; i++) {
    seed = (seed * 1664525 + 1013904223) % 4294967296; // LCG simple
    buffer.write(chars[seed % chars.length]);
  }
  return buffer.toString();
}

/// Trunca un texto con elipsis.
String truncate(String text, int maxLength, {String suffix = '…'}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - suffix.length)}$suffix';
}

/// Capitaliza la primera letra de cada palabra.
String capitalizeWords(String text) {
  return text.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

/// Valida formato de email.
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

/// Valida contraseña mínima (8 chars, 1 mayúscula, 1 número).
bool isStrongPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);
}

/// Muestra un SnackBar con estilo consistente.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onAction,
  String? actionLabel,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: isError ? Colors.white : Theme.of(context).colorScheme.primary,
              onPressed: onAction,
            )
          : null,
    ),
  );
}

/// Muestra un diálogo de confirmación.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Genera un color determinista a partir de un string (para avatares).
Color colorFromString(String input) {
  var hash = 0;
  for (var i = 0; i < input.length; i++) {
    hash = input.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1, hue, 0.55, 0.85).toColor();
}

/// Calcula el porcentaje de progreso (0.0 a 1.0) redondeado.
double clampProgress(double value) => value.clamp(0.0, 1.0);

/// Extensiones útiles para BuildContext.
extension ContextUtils on BuildContext {
  /// Navega y limpia el stack.
  void goNamedAndClear(String name, {Object? extra}) {
    Navigator.of(this).pushNamedAndRemoveUntil(name, (route) => false, arguments: extra);
  }

  /// Cierra teclado.
  void hideKeyboard() => FocusScope.of(this).unfocus();

  /// Ancho de pantalla.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Alto de pantalla.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Es móvil (ancho < 600).
  bool get isMobile => screenWidth < 600;

  /// Es tablet (ancho >= 600 && < 1200).
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Es desktop (ancho >= 1200).
  bool get isDesktop => screenWidth >= 1200;
}

/// Extensiones para DateTime.
extension DateTimeUtils on DateTime {
  /// Inicio del día (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Fin del día (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Verifica si es hoy.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Verifica si es ayer.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Verifica si es esta semana.
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).startOfDay;
    final endOfWeek = startOfWeek.add(const Duration(days: 6)).endOfDay;
    return isAfter(startOfWeek) && isBefore(endOfWeek);
  }
}