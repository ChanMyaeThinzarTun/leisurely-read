import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'warning', 'info', 'alert'
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'read': read,
    'createdAt': createdAt,
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
      );
}
