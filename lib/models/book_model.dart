import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String writerId;
  final String title;
  final String coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.writerId,
    required this.title,
    required this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'writerId': writerId,
    'title': title,
    'coverImageUrl': coverImageUrl,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory BookModel.fromMap(Map<String, dynamic> data, String id) => BookModel(
    id: id,
    writerId: data['writerId'] ?? '',
    title: data['title'] ?? '',
    coverImageUrl: data['coverImageUrl'] ?? '',
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
