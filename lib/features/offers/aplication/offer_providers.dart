
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repartojusto/features/offers/data/offer_repository.dart';
import 'package:repartojusto/features/offers/domain/offer.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository();
});

final offersProvider = StreamProvider.family<
    List<Offer>,
    ({String groupId, String projectId, String taskId})>(
  (ref, params) {
    return ref.watch(offerRepositoryProvider).watchOffers(
          groupId: params.groupId,
          projectId: params.projectId,
          taskId: params.taskId,
        );
  },
);
