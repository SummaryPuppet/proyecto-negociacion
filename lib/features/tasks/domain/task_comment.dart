class TaskComment {
  final String id;
  final String authorId;
  final String message;
  final int createdAt;

  const TaskComment({
    required this.id,
    required this.authorId,
    required this.message,
    required this.createdAt,
  });

  factory TaskComment.fromMap(String id, Map<String, dynamic> data) {
    return TaskComment(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: data['createdAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'authorId': authorId, 'message': message, 'createdAt': createdAt};
  }
}
