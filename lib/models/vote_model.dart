import 'package:cloud_firestore/cloud_firestore.dart';

class VoteModel {
  final String id;
  final String chapterId;
  final String userId;
  final int voteValue; // 1 for thumbs up, -1 for thumbs down
  final DateTime createdAt;

  VoteModel({
    required this.id,
    required this.chapterId,
    required this.userId,
    required this.voteValue,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'chapterId': chapterId,
    'userId': userId,
    'voteValue': voteValue,
    'createdAt': createdAt,
  };

  factory VoteModel.fromMap(Map<String, dynamic> data, String id) => VoteModel(
    id: id,
    chapterId: data['chapterId'] ?? '',
    userId: data['userId'] ?? '',
    voteValue: data['voteValue'] ?? 0,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
