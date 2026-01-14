import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String bookId;
  final String? chapterId;
  final String userId;
  final String message;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'chapterId': chapterId,
    'userId': userId,
    'message': message,
    'createdAt': createdAt,
  };

  factory CommentModel.fromMap(Map<String, dynamic> data, String id) =>
      CommentModel(
        id: id,
        bookId: data['bookId'] ?? '',
        chapterId: data['chapterId'],
        userId: data['userId'] ?? '',
        message: data['message'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
