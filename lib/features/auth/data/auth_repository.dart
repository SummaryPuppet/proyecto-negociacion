import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/firebase/google_auth_config.dart' as google_auth_config;

class AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Stream de cambios de autenticación.
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actual.
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Registro con email y contraseña.
  Future<Result<firebase_auth.UserCredential>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (!isValidEmail(email)) {
        return Failure(const ValidationError('Email inválido'));
      }
      if (!isStrongPassword(password)) {
        return Failure(const ValidationError('Contraseña débil: mín. 8 chars, 1 mayúscula, 1 número'));
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Actualizar displayName
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      }

      return Success(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Inicio de sesión con email y contraseña.
  Future<Result<firebase_auth.UserCredential>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (!isValidEmail(email)) {
        return Failure(const ValidationError('Email inválido'));
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return Success(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Inicio de sesión con Google.
  Future<Result<firebase_auth.UserCredential>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: usar popup
        final googleProvider = GoogleAuthProvider();
        final credential = await _auth.signInWithPopup(googleProvider);
        return Success(credential);
      } else {
        // Android/iOS: usar google_sign_in
        await GoogleSignIn.instance.initialize(
          serverClientId: googleWebClientId,
        );
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null) {
          return Failure(const AuthError('No se obtuvo el token de Google'));
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        final userCredential = await _auth.signInWithCredential(credential);
        return Success(userCredential);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } on GoogleSignInException catch (e) {
      return Failure(AuthError(e.toString(), e.code.toString()));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Recuperación de contraseña.
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      if (!isValidEmail(email)) {
        return Failure(const ValidationError('Email inválido'));
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Cerrar sesión.
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Web client ID para Google Sign-In en Android.
  static String get googleWebClientId => google_auth_config.googleWebClientId;
}