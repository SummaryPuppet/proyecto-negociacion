import 'package:flutter/foundation.dart';

/// Excepción base de la aplicación.
sealed class AppError implements Exception {
  const AppError(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppError($code): $message';
}

/// Error de autenticación.
class AuthError extends AppError {
  const AuthError(super.message, [super.code]);
}

/// Error de red / Firestore.
class NetworkError extends AppError {
  const NetworkError(super.message, [super.code]);
}

/// Error de validación de datos.
class ValidationError extends AppError {
  const ValidationError(super.message, [super.code]);
}

/// Error de permisos.
class PermissionError extends AppError {
  const PermissionError(super.message, [super.code]);
}

/// Error de lógica de negocio.
class BusinessError extends AppError {
  const BusinessError(super.message, [super.code]);
}

/// Error desconocido.
class UnknownError extends AppError {
  const UnknownError(super.message, [super.code]);
}

/// Convierte cualquier excepción en un [AppError] tipado.
AppError mapToAppError(Object error, StackTrace stackTrace) {
  if (error is AppError) return error;

  final message = error.toString();

  // Firebase Auth errors
  if (message.contains('email-already-in-use')) {
    return const AuthError('El email ya está registrado', 'email-already-in-use');
  }
  if (message.contains('weak-password')) {
    return const AuthError('La contraseña es muy débil', 'weak-password');
  }
  if (message.contains('invalid-email')) {
    return const AuthError('Email inválido', 'invalid-email');
  }
  if (message.contains('user-not-found')) {
    return const AuthError('Usuario no encontrado', 'user-not-found');
  }
  if (message.contains('wrong-password')) {
    return const AuthError('Contraseña incorrecta', 'wrong-password');
  }
  if (message.contains('too-many-requests')) {
    return const AuthError('Demasiados intentos. Intenta más tarde', 'too-many-requests');
  }
  if (message.contains('network-request-failed')) {
    return const NetworkError('Error de conexión. Verifica tu internet', 'network-error');
  }

  // Firestore permission errors
  if (message.contains('permission-denied') || message.contains('Missing or insufficient permissions')) {
    return const PermissionError('No tienes permisos para esta acción', 'permission-denied');
  }

  // Validation
  if (message.contains('invalid-argument') || message.contains('ArgumentError')) {
    return ValidationError(message, 'invalid-argument');
  }

  // Log en debug
  if (kDebugMode) {
    debugPrint('AppError: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  return UnknownError(message);
}

/// Resultado que puede ser un éxito o un error.
sealed class Result<T> {
  const Result();

  /// Si el resultado es exitoso.
  bool get isSuccess => this is Success<T>;

  /// Si el resultado es un error.
  bool get isError => this is Failure<T>;

  /// Obtiene el valor si es éxito, lanza si es error.
  T get value {
    if (this is Success<T>) return (this as Success<T>).value;
    throw StateError('Resultado es un error: ${(this as Failure<T>).error}');
  }

  /// Obtiene el error si es error, lanza si es éxito.
  AppError get error {
    if (this is Failure<T>) return (this as Failure<T>).error;
    throw StateError('Resultado es exitoso');
  }

  /// Transforma el valor si es éxito.
  Result<U> map<U>(U Function(T) transform) {
    if (this is Success<T>) {
      return Success(transform((this as Success<T>).value));
    }
    return Failure((this as Failure<T>).error);
  }

  /// Transforma el error si es error.
  Result<T> mapError(AppError Function(AppError) transform) {
    if (this is Failure<T>) {
      return Failure(transform((this as Failure<T>).error));
    }
    return this;
  }
}

/// Resultado exitoso.
class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// Resultado fallido.
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppError error;
}

/// Extension para manejar Results fácilmente.
extension ResultX<T> on Result<T> {
  /// Ejecuta [onSuccess] si es éxito, [onError] si es error.
  void fold({
    required void Function(T) onSuccess,
    required void Function(AppError) onError,
  }) {
    if (this is Success<T>) {
      onSuccess((this as Success<T>).value);
    } else {
      onError((this as Failure<T>).error);
    }
  }

  /// Versión async de fold.
  Future<void> foldAsync({
    required Future<void> Function(T) onSuccess,
    required Future<void> Function(AppError) onError,
  }) async {
    if (this is Success<T>) {
      await onSuccess((this as Success<T>).value);
    } else {
      await onError((this as Failure<T>).error);
    }
  }
}