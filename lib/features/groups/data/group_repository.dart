import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:repartojusto/features/groups/domain/app_group.dart';
import 'package:repartojusto/features/groups/domain/approval_config.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/core/utils/utils.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _joinCodesCollection =>
      _firestore.collection('joinCodes');

  /// Crea un grupo con código de invitación único (transacción).
  Future<Result<AppGroup>> createGroup({
    required String name,
    required String period,
    required String teacherId,
  }) async {
    try {
      final group = await _firestore.runTransaction<AppGroup>((transaction) async {
        String joinCode = '';
        DocumentReference<Map<String, dynamic>>? joinCodeRef;
        bool codeExists = true;

        // Generar código único reintentando hasta 5 veces
        for (var i = 0; i < 5 && codeExists; i++) {
          joinCode = generateJoinCode();
          joinCodeRef = _joinCodesCollection.doc(joinCode);
          final doc = await transaction.get(joinCodeRef!);
          codeExists = doc.exists;
        }

        if (codeExists || joinCodeRef == null) {
          throw Exception('No se pudo generar código único');
        }

        final groupRef = _groupsCollection.doc();
        final group = AppGroup(
          id: groupRef.id,
          name: name.trim(),
          period: period.trim(),
          teacherId: teacherId,
          memberIds: [teacherId],
          joinCode: joinCode,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final groupData = group.toJson();
        groupData['approvalConfig'] = group.approvalConfig.toJson();
        transaction.set(groupRef, groupData);
        transaction.set(joinCodeRef!, {
          'groupId': groupRef.id,
          'groupName': name.trim(),
          'teacherId': teacherId,
        });

        return group;
      });
      return Success(group);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Se une a un grupo por código de invitación.
  Future<Result<AppGroup>> joinByCode({
    required String code,
    required String userId,
  }) async {
    try {
      final group = await _firestore.runTransaction<AppGroup>((transaction) async {
        final joinCodeRef = _joinCodesCollection.doc(code.toUpperCase());
        final joinCodeDoc = await transaction.get(joinCodeRef);
        if (!joinCodeDoc.exists) {
          throw Exception('Código inválido');
        }

        final groupId = joinCodeDoc.data()!['groupId'] as String;
        final groupRef = _groupsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Grupo no encontrado');
        }

        final group = AppGroup.fromJson(groupDoc.data()!);
        if (group.memberIds.contains(userId)) {
          throw Exception('Ya eres miembro');
        }

        final updatedMemberIds = [...group.memberIds, userId];
        transaction.update(groupRef, {'memberIds': updatedMemberIds});

        return group.copyWith(memberIds: updatedMemberIds);
      });
      return Success(group);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Código inválido') ||
          errorMsg.contains('Grupo no encontrado') ||
          errorMsg.contains('Ya eres miembro')) {
        return Failure(BusinessError(errorMsg));
      }
      return Failure(mapToAppError(e, st));
    }
  }

  /// Observa los grupos del usuario.
  Stream<List<AppGroup>> watchMyGroups(String userId) {
    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map((doc) => AppGroup.fromJson(doc.data()))
              .toList();
          groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return groups;
        });
  }

  /// Observa un grupo específico.
  Stream<AppGroup?> watchGroup(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppGroup.fromJson(doc.data()!);
    });
  }

  /// Obtiene un grupo una sola vez.
  Future<AppGroup?> getGroup(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (!doc.exists) return null;
    return AppGroup.fromJson(doc.data()!);
  }

  /// Nombra jefe de grupo (solo docente).
  Future<Result<void>> setLeader({
    required String groupId,
    required String newLeaderId,
  }) async {
    try {
      await _groupsCollection.doc(groupId).update({'leaderId': newLeaderId});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Quita al jefe actual (solo docente).
  Future<Result<void>> clearLeader(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).update({'leaderId': ''});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Expulsa a un miembro (solo docente, no puede expulsarse a sí mismo).
  Future<Result<void>> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _groupsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) throw Exception('Grupo no encontrado');

        final group = AppGroup.fromJson(groupDoc.data()!);
        if (!group.memberIds.contains(memberId)) {
          throw Exception('No es miembro');
        }

        final updated = [...group.memberIds]..remove(memberId);
        String? newLeader = group.leaderId;
        if (group.leaderId == memberId) {
          newLeader = '';
        }

        transaction.update(groupRef, {
          'memberIds': updated,
          if (newLeader != null) 'leaderId': newLeader,
        });
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// El usuario sale del grupo voluntariamente.
  Future<Result<void>> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _groupsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) throw Exception('Grupo no encontrado');

        final group = AppGroup.fromJson(groupDoc.data()!);
        if (!group.memberIds.contains(userId)) {
          throw Exception('No eres miembro');
        }
        if (group.teacherId == userId) {
          throw Exception('El docente no puede abandonar; elimina el grupo');
        }

        final updated = [...group.memberIds]..remove(userId);
        String? newLeader = group.leaderId;
        if (group.leaderId == userId) {
          newLeader = '';
        }

        transaction.update(groupRef, {
          'memberIds': updated,
          if (newLeader != null) 'leaderId': newLeader,
        });
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      final errorMsg = e.toString();
      if (errorMsg.contains('no eres miembro') ||
          errorMsg.contains('docente no puede')) {
        return Failure(BusinessError(errorMsg));
      }
      return Failure(mapToAppError(e, st));
    }
  }

  /// Elimina el grupo completo (solo docente).
  Future<Result<void>> deleteGroup(String groupId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _groupsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) throw Exception('Grupo no encontrado');

        final group = AppGroup.fromJson(groupDoc.data()!);
        transaction.delete(groupRef);
        transaction.delete(_joinCodesCollection.doc(group.joinCode));
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Regenera el código de invitación (solo docente).
  Future<Result<String>> regenerateJoinCode(String groupId) async {
    try {
      final newCode = await _firestore.runTransaction<String>((transaction) async {
        final groupRef = _groupsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) throw Exception('Grupo no encontrado');

        final group = AppGroup.fromJson(groupDoc.data()!);
        String code = '';
        DocumentReference<Map<String, dynamic>>? newCodeRef;
        bool exists = true;

        for (var i = 0; i < 5 && exists; i++) {
          code = generateJoinCode();
          newCodeRef = _joinCodesCollection.doc(code);
          final doc = await transaction.get(newCodeRef!);
          exists = doc.exists;
        }

        if (exists || newCodeRef == null) throw Exception('No se pudo generar código');

        // Borrar código viejo
        transaction.delete(_joinCodesCollection.doc(group.joinCode));
        // Crear nuevo
        transaction.set(newCodeRef!, {
          'groupId': groupId,
          'groupName': group.name,
          'teacherId': group.teacherId,
        });
        // Actualizar grupo
        transaction.update(groupRef, {'joinCode': code});

        return code;
      });
      return Success(newCode);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Actualiza la configuración de aprobación (solo docente).
  Future<Result<void>> updateApprovalConfig({
    required String groupId,
    required ApprovalConfig config,
  }) async {
    try {
      await _groupsCollection.doc(groupId).update({'approvalConfig': config.toJson()});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }
}