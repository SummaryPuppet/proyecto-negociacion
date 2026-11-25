import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/auth/domain/app_user.dart';
import 'package:repartojusto/core/errors/app_error.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Crea el perfil del usuario tras elegir rol.
  Future<Result<void>> createProfile({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? photoUrl,
  }) async {
    try {
      final user = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        photoUrl: photoUrl,
        role: role,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _usersCollection.doc(uid).set(user.toJson());
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Observa el perfil del usuario en tiempo real.
  Stream<AppUser?> watchProfile(String uid) {
    return _usersCollection
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data()!);
    });
  }

  /// Obtiene el perfil una sola vez.
  Future<AppUser?> getProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromJson(doc.data()!);
  }

  /// Actualiza campos permitidos del perfil (no el rol).
  Future<Result<void>> updateProfile({
    required String uid,
    String? name,
    String? photoUrl,
    List<String>? skills,
    AvailabilityMap? availability,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (skills != null) data['skills'] = skills;
      if (availability != null) data['availability'] = availability;
      if (data.isEmpty) return const Success(null);
      await _usersCollection.doc(uid).update(data);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Añade un grupo al usuario.
  Future<Result<void>> addGroupId(String uid, String groupId) async {
    try {
      await _usersCollection.doc(uid).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Elimina un grupo del usuario.
  Future<Result<void>> removeGroupId(String uid, String groupId) async {
    try {
      await _usersCollection.doc(uid).update({
        'groupIds': FieldValue.arrayRemove([groupId]),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }
}