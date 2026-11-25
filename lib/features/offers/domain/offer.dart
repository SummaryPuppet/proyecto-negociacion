
class Offer {
  final String id;
  final String authorId;
  final int points;
  final int hours;
  final String argument;
  final String? parentOfferId;
  final String status;
  final Map<String, dynamic> votes;
  final int createdAt;

  const Offer({
    required this.id,
    required this.authorId,
    required this.points,
    required this.hours,
    required this.argument,
    this.parentOfferId,
    this.status = 'pending',
    this.votes = const {},
    required this.createdAt,
  });

  factory Offer.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return Offer(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      hours: (data['hours'] as num?)?.toInt() ?? 0,
      argument: data['argument'] as String? ?? '',
      parentOfferId: data['parentOfferId'] as String?,
      status: data['status'] as String? ?? 'pending',
      votes: Map<String, dynamic>.from(data['votes'] ?? {}),
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'points': points,
      'hours': hours,
      'argument': argument,
      'parentOfferId': parentOfferId,
      'status': status,
      'votes': votes,
      'createdAt': createdAt,
    };
  }

  bool get isCounterOffer => parentOfferId != null;
}
