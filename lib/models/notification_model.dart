import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String
  type; // 'warning', 'info', 'alert', 'vote', 'comment', 'reply', 'new_chapter'
  final bool read;
  final DateTime createdAt;
  // Additional data for navigation
  final String? bookId;
  final String? chapterId;
  final int? chapterNumber;
  final String? commentId;
  final String? commentText;
  final String? fromUserId;
  final String? fromUserNickname;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.bookId,
    this.chapterId,
    this.chapterNumber,
    this.commentId,
    this.commentText,
    this.fromUserId,
    this.fromUserNickname,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'read': read,
    'createdAt': createdAt,
    'bookId': bookId,
    'chapterId': chapterId,
    'chapterNumber': chapterNumber,
    'commentId': commentId,
    'commentText': commentText,
    'fromUserId': fromUserId,
    'fromUserNickname': fromUserNickname,
  };

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) =>
      NotificationModel(
        id: id,
        userId: data['userId'] ?? '',
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        type: data['type'] ?? 'info',
        read: data['read'] ?? false,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        bookId: data['bookId'],
        chapterId: data['chapterId'],
        chapterNumber: data['chapterNumber'],
        commentId: data['commentId'],
        commentText: data['commentText'],
        fromUserId: data['fromUserId'],
        fromUserNickname: data['fromUserNickname'],
      );
}
