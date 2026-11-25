import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repartojusto/features/offers/domain/offer.dart';
import 'package:repartojusto/core/errors/app_error.dart';

class OfferRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _offersCollection({
    required String groupId,
    required String projectId,
    required String taskId,
  }) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .collection('offers');
  }

  DocumentReference<Map<String, dynamic>> _offerDoc({
    required String groupId,
    required String projectId,
    required String taskId,
    required String offerId,
  }) {
    return _offersCollection(
      groupId: groupId,
      projectId: projectId,
      taskId: taskId,
    ).doc(offerId);
  }

  DocumentReference<Map<String, dynamic>> _taskDoc({
    required String groupId,
    required String projectId,
    required String taskId,
  }) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId);
  }

  CollectionReference<Map<String, dynamic>> _activityCollection({
    required String groupId,
  }) {
    return _firestore.collection('groups').doc(groupId).collection('activity');
  }

  /// Guarda una oferta nueva o una contraoferta.
  Future<Result<Offer>> createOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String authorId,
    required int points,
    required int hours,
    required String argument,
    String? parentOfferId,
  }) async {
    try {
      final collection = _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      );

      final document = collection.doc();
      final now = DateTime.now().millisecondsSinceEpoch;

      final offer = Offer(
        id: document.id,
        taskId: taskId,
        projectId: projectId,
        groupId: groupId,
        authorId: authorId,
        points: points,
        hours: hours,
        argument: argument.trim(),
        parentOfferId: parentOfferId,
        status: 'pending',
        votes: {},
        createdAt: now,
        updatedAt: now,
      );

      await document.set(offer.toJson());

      // Si es contraoferta, actualizar la oferta padre a 'countered'
      if (parentOfferId != null) {
        await _offerDoc(
          groupId: groupId,
          projectId: projectId,
          taskId: taskId,
          offerId: parentOfferId,
        ).update({
          'status': 'countered',
          'updatedAt': now,
        });
      }

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: authorId,
        type: parentOfferId != null ? 'counter_offer_created' : 'offer_created',
        payload: {
          'offerId': document.id,
          'taskId': taskId,
          'points': points,
          'hours': hours,
          'parentOfferId': parentOfferId,
        },
      );

      return Success(offer);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Emite un voto (approve/reject) en una oferta.
  Future<Result<void>> voteOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String offerId,
    required String voterId,
    required String vote, // 'approve' | 'reject'
    required bool isLeader,
    required bool isTeacher,
  }) async {
    try {
      final offerRef = _offerDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
        offerId: offerId,
      );

      await _firestore.runTransaction((transaction) async {
        final offerSnap = await transaction.get(offerRef);
        if (!offerSnap.exists) {
          throw Exception('Oferta no encontrada');
        }

        final offer = Offer.fromJson(offerSnap.data()!);

        // No puede votar el autor
        if (offer.authorId == voterId) {
          throw Exception('El autor no puede votar su propia oferta');
        }

        // Solo se puede votar ofertas pendientes
        if (!offer.isPending) {
          throw Exception('Solo se pueden votar ofertas pendientes');
        }

        final votes = Map<String, String>.from(offer.votes);
        votes[voterId] = vote;

        transaction.update(offerRef, {
          'votes': votes,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      });

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: voterId,
        type: 'offer_voted',
        payload: {
          'offerId': offerId,
          'taskId': taskId,
          'vote': vote,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Aprueba una oferta (líder o docente) - transacción atómica.
  Future<Result<void>> approveOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String offerId,
    required String approverId,
    required bool isLeader,
    required bool isTeacher,
  }) async {
    try {
      final offerRef = _offerDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
        offerId: offerId,
      );
      final taskRef = _taskDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      );

      // Obtener la oferta ANTES de la transacción para el activity log
      final offerSnap = await offerRef.get();
      if (!offerSnap.exists) {
        return Failure(const BusinessError('Oferta no encontrada'));
      }
      final offer = Offer.fromJson(offerSnap.data()!);

      // Obtener ofertas relacionadas ANTES de la transacción
      final otherOffersSnap = await _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      ).where('status', isEqualTo: 'pending').get();

      final counterOffersSnap = await _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      ).where('parentOfferId', isEqualTo: offerId).get();

      await _firestore.runTransaction((transaction) async {
        // Solo líder o docente pueden aprobar
        if (!isLeader && !isTeacher) {
          throw Exception('Solo el líder o docente pueden aprobar ofertas');
        }

        if (!offer.isPending) {
          throw Exception('Solo se pueden aprobar ofertas pendientes');
        }

        final now = DateTime.now().millisecondsSinceEpoch;

        // 1. Marcar oferta como aprobada
        transaction.update(offerRef, {
          'status': 'approved',
          'resolvedAt': now,
          'resolvedBy': approverId,
          'resolution': 'approved',
          'updatedAt': now,
        });

        // 2. Asignar tarea al autor de la oferta
        transaction.update(taskRef, {
          'assigneeId': offer.authorId,
          'status': 'assigned',
          'closedAt': now,
          'updatedAt': now,
        });

        // 3. Rechazar las demás ofertas de la tarea
        for (final doc in otherOffersSnap.docs) {
          if (doc.id != offerId) {
            transaction.update(doc.reference, {
              'status': 'rejected',
              'resolvedAt': now,
              'resolvedBy': approverId,
              'resolution': 'rejected',
              'updatedAt': now,
            });
          }
        }

        // 4. Rechazar contraofertas de esta oferta
        for (final doc in counterOffersSnap.docs) {
          transaction.update(doc.reference, {
            'status': 'rejected',
            'resolvedAt': now,
            'resolvedBy': approverId,
            'resolution': 'rejected',
            'updatedAt': now,
          });
        }
      });

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: approverId,
        type: 'offer_approved',
        payload: {
          'offerId': offerId,
          'taskId': taskId,
          'assigneeId': offer.authorId,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Forza la asignación de una oferta (solo docente).
  Future<Result<void>> forceAssignOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String offerId,
    required String teacherId,
    required String reason,
  }) async {
    try {
      final offerRef = _offerDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
        offerId: offerId,
      );
      final taskRef = _taskDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      );

      // Obtener ofertas relacionadas ANTES de la transacción
      final otherOffersSnap = await _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      ).where('status', isEqualTo: 'pending').get();

      final counterOffersSnap = await _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      ).where('parentOfferId', isEqualTo: offerId).get();

      // Obtener la oferta para tener el authorId
      final offerSnap = await offerRef.get();
      final offer = Offer.fromJson(offerSnap.data()!);

      await _firestore.runTransaction((transaction) async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // 1. Marcar oferta como forzada
        transaction.update(offerRef, {
          'status': 'forced',
          'resolvedAt': now,
          'resolvedBy': teacherId,
          'resolution': 'forced',
          'updatedAt': now,
        });

        // 2. Asignar tarea con estado 'forced'
        transaction.update(taskRef, {
          'assigneeId': offer.authorId,
          'status': 'forced',
          'forcedReason': reason,
          'closedAt': now,
          'updatedAt': now,
        });

        // 3. Rechazar las demás ofertas
        for (final doc in otherOffersSnap.docs) {
          if (doc.id != offerId) {
            transaction.update(doc.reference, {
              'status': 'rejected',
              'resolvedAt': now,
              'resolvedBy': teacherId,
              'resolution': 'rejected',
              'updatedAt': now,
            });
          }
        }

        // 4. Rechazar contraofertas de esta oferta
        for (final doc in counterOffersSnap.docs) {
          transaction.update(doc.reference, {
            'status': 'rejected',
            'resolvedAt': now,
            'resolvedBy': teacherId,
            'resolution': 'rejected',
            'updatedAt': now,
          });
        }
      });

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: teacherId,
        type: 'offer_forced',
        payload: {
          'offerId': offerId,
          'taskId': taskId,
          'reason': reason,
          'assigneeId': offer.authorId,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Acepta una contraoferta (el estudiante original la acepta).
  Future<Result<void>> acceptCounterOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String counterOfferId,
    required String studentId,
  }) async {
    try {
      final counterOfferRef = _offerDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
        offerId: counterOfferId,
      );

      // Obtener la contraoferta primero
      final counterSnap = await counterOfferRef.get();
      if (!counterSnap.exists) {
        return Failure(const BusinessError('Contraoferta no encontrada'));
      }

      final counterOffer = Offer.fromJson(counterSnap.data()!);

      if (counterOffer.authorId == studentId) {
        return Failure(const BusinessError('No puedes aceptar tu propia contraoferta'));
      }

      if (!counterOffer.isPending) {
        return Failure(const BusinessError('Solo se pueden aceptar contraofertas pendientes'));
      }

      if (counterOffer.parentOfferId == null) {
        return Failure(const BusinessError('No es una contraoferta'));
      }

      // Obtener ofertas relacionadas ANTES de la transacción
      final otherCountersSnap = await _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      ).where('parentOfferId', isEqualTo: counterOffer.parentOfferId).get();

      final parentOfferRef = _offerDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
        offerId: counterOffer.parentOfferId!,
      );

      final taskRef = _taskDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      );

      await _firestore.runTransaction((transaction) async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // 1. Aprobar la contraoferta
        transaction.update(counterOfferRef, {
          'status': 'approved',
          'resolvedAt': now,
          'resolvedBy': studentId,
          'resolution': 'approved',
          'updatedAt': now,
        });

        // 2. Rechazar la oferta original
        transaction.update(parentOfferRef, {
          'status': 'rejected',
          'resolvedAt': now,
          'resolvedBy': studentId,
          'resolution': 'rejected',
          'updatedAt': now,
        });

        // 3. Rechazar otras contraofertas de la misma oferta padre
        for (final doc in otherCountersSnap.docs) {
          if (doc.id != counterOfferId) {
            transaction.update(doc.reference, {
              'status': 'rejected',
              'resolvedAt': now,
              'resolvedBy': studentId,
              'resolution': 'rejected',
              'updatedAt': now,
            });
          }
        }

        // 4. Asignar tarea
        transaction.update(taskRef, {
          'assigneeId': counterOffer.authorId,
          'status': 'assigned',
          'closedAt': now,
          'updatedAt': now,
        });
      });

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: studentId,
        type: 'counter_offer_accepted',
        payload: {
          'counterOfferId': counterOfferId,
          'taskId': taskId,
          'assigneeId': counterOffer.authorId,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Rechaza una contraoferta.
  Future<Result<void>> rejectCounterOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String counterOfferId,
    required String studentId,
  }) async {
    try {
      final counterOfferRef = _offerDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
        offerId: counterOfferId,
      );

      // Obtener la contraoferta primero
      final counterSnap = await counterOfferRef.get();
      if (!counterSnap.exists) {
        return Failure(const BusinessError('Contraoferta no encontrada'));
      }

      final counterOffer = Offer.fromJson(counterSnap.data()!);

      if (counterOffer.authorId == studentId) {
        return Failure(const BusinessError('No puedes rechazar tu propia contraoferta'));
      }

      if (!counterOffer.isPending) {
        return Failure(const BusinessError('Solo se pueden rechazar contraofertas pendientes'));
      }

      await _firestore.runTransaction((transaction) async {
        final now = DateTime.now().millisecondsSinceEpoch;

        transaction.update(counterOfferRef, {
          'status': 'rejected',
          'resolvedAt': now,
          'resolvedBy': studentId,
          'resolution': 'rejected',
          'updatedAt': now,
        });
      });

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: studentId,
        type: 'counter_offer_rejected',
        payload: {
          'counterOfferId': counterOfferId,
          'taskId': taskId,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Reabre una tarea (solo docente).
  Future<Result<void>> reopenTask({
    required String groupId,
    required String projectId,
    required String taskId,
    required String teacherId,
    required String reason,
  }) async {
    try {
      final taskRef = _taskDoc(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      );

      // Obtener ofertas rechazadas/forzadas ANTES de la transacción
      final offersSnap = await _offersCollection(
        groupId: groupId,
        projectId: projectId,
        taskId: taskId,
      ).where('status', whereIn: ['rejected', 'forced']).get();

      final now = DateTime.now().millisecondsSinceEpoch;

      await _firestore.runTransaction((transaction) async {
        final taskSnap = await transaction.get(taskRef);
        if (!taskSnap.exists) {
          throw Exception('Tarea no encontrada');
        }

        transaction.update(taskRef, {
          'status': 'negotiating',
          'assigneeId': FieldValue.delete(),
          'forcedReason': FieldValue.delete(),
          'closedAt': FieldValue.delete(),
          'updatedAt': now,
        });

        // Reabrir ofertas rechazadas/forzadas a pending
        for (final doc in offersSnap.docs) {
          transaction.update(doc.reference, {
            'status': 'pending',
            'resolvedAt': FieldValue.delete(),
            'resolvedBy': FieldValue.delete(),
            'resolution': FieldValue.delete(),
            'updatedAt': now,
          });
        }
      });

      // Registrar actividad
      await _logActivity(
        groupId: groupId,
        projectId: projectId,
        actorId: teacherId,
        type: 'task_reopened',
        payload: {
          'taskId': taskId,
          'reason': reason,
        },
      );

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Verifica si asignar la tarea superaría la cuota de equidad (+20%).
  Future<Result<Map<String, dynamic>>> checkFairnessQuota({
    required String groupId,
    required String projectId,
    required String taskId,
    required String studentId,
    required int taskPoints,
  }) async {
    try {
      // Obtener puntos totales del proyecto
      final projectDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        return Failure(const BusinessError('Proyecto no encontrado'));
      }

      final projectData = projectDoc.data()!;
      final totalPoints = projectData['totalPoints'] as int? ?? 0;
      final memberIds = List<String>.from(projectData['memberIds'] ?? []);
      final studentCount = memberIds.length;

      if (studentCount == 0) {
        return const Success({'exceedsQuota': false, 'quota': 0, 'currentPoints': 0});
      }

      final fairQuota = totalPoints / studentCount;
      final maxAllowed = fairQuota * 1.2; // +20%

      // Calcular puntos actuales del estudiante
      final tasksSnap = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .where('assigneeId', isEqualTo: studentId)
          .where('status', whereIn: ['assigned', 'forced'])
          .get();

      int currentPoints = 0;
      for (final doc in tasksSnap.docs) {
        currentPoints += doc.data()['weight'] as int? ?? 0;
      }

      final newTotal = currentPoints + taskPoints;
      final exceedsQuota = newTotal > maxAllowed;

      return Success({
        'exceedsQuota': exceedsQuota,
        'quota': fairQuota,
        'maxAllowed': maxAllowed,
        'currentPoints': currentPoints,
        'newTotal': newTotal,
        'studentCount': studentCount,
        'totalPoints': totalPoints,
      });
    } on FirebaseException catch (e) {
      return Failure(mapToAppError(e, StackTrace.current));
    } catch (e, st) {
      return Failure(mapToAppError(e, st));
    }
  }

  /// Escucha las ofertas de una tarea en tiempo real.
  Stream<List<Offer>> watchOffers({
    required String groupId,
    required String projectId,
    required String taskId,
  }) {
    return _offersCollection(
      groupId: groupId,
      projectId: projectId,
      taskId: taskId,
    ).orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Offer.fromJson(doc.data()))
          .toList(),
    );
  }

  /// Obtiene una oferta por ID.
  Future<Offer?> getOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String offerId,
  }) async {
    final doc = await _offerDoc(
      groupId: groupId,
      projectId: projectId,
      taskId: taskId,
      offerId: offerId,
    ).get();
    if (!doc.exists) return null;
    return Offer.fromJson(doc.data()!);
  }

  Future<void> _logActivity({
    required String groupId,
    required String projectId,
    required String actorId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final activityRef = _activityCollection(groupId: groupId).doc();
      await activityRef.set({
        'projectId': projectId,
        'type': type,
        'actorId': actorId,
        'payload': payload,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // No fallar si no se puede registrar la actividad
    }
  }
}