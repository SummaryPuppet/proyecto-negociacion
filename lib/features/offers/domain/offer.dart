import 'package:freezed_annotation/freezed_annotation.dart';

part 'offer.freezed.dart';
part 'offer.g.dart';

@freezed
abstract class Offer with _$Offer {
  @JsonSerializable(explicitToJson: true)
  const factory Offer({
    required String id,
    required String taskId,
    required String projectId,
    required String groupId,
    required String authorId,
    required int points,
    required int hours,
    required String argument,
    String? parentOfferId,
    @Default('pending') String status, // pending, approved, rejected, forced, countered
    @Default({}) Map<String, String> votes, // uid -> 'approve' | 'reject'
    int? resolvedAt,
    String? resolvedBy,
    String? resolution, // approved, rejected, forced
    @Default(0) int createdAt,
    @Default(0) int updatedAt,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
}

extension OfferX on Offer {
  bool get isCounterOffer => parentOfferId != null;
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isForced => status == 'forced';
  bool get isCountered => status == 'countered';

  int get approveCount => votes.values.where((v) => v == 'approve').length;
  int get rejectCount => votes.values.where((v) => v == 'reject').length;

  int calculateScore({int leaderWeight = 2}) {
    int score = 0;
    votes.forEach((uid, vote) {
      int weight = 1; // Se ajustará en el repositorio según sea líder/docente
      if (vote == 'approve') {
        score += weight;
      } else {
        score -= weight;
      }
    });
    return score;
  }

  Offer copyWithTimestamp() => copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
}