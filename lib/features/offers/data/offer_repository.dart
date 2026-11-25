
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repartojusto/features/offers/domain/offer.dart';

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

  /// Guarda una oferta nueva o una contraoferta.
  Future<Offer> createOffer({
    required String groupId,
    required String projectId,
    required String taskId,
    required String authorId,
    required int points,
    required int hours,
    required String argument,
    String? parentOfferId,
  }) async {
    final collection = _offersCollection(
      groupId: groupId,
      projectId: projectId,
      taskId: taskId,
    );

    final document = collection.doc();

    final offer = Offer(
      id: document.id,
      authorId: authorId,
      points: points,
      hours: hours,
      argument: argument.trim(),
      parentOfferId: parentOfferId,
      status: 'pending',
      votes: const {},
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await document.set(offer.toFirestore());

    return offer;
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
          .map((doc) => Offer.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }
}
