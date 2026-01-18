import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String writerId;
  final String writerNickname;
  final String title;
  final String coverImageUrl;
  final String description;
  final String category;
  final List<String> tags;
  final bool isMature;
  final bool isCompleted;
  final bool isDraft;
  final int readCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.writerId,
    this.writerNickname = '',
    required this.title,
    required this.coverImageUrl,
    this.description = '',
    this.category = '',
    this.tags = const [],
    this.isMature = false,
    this.isCompleted = false,
    this.isDraft = false,
    this.readCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'writerId': writerId,
    'writerNickname': writerNickname,
    'title': title,
    'coverImageUrl': coverImageUrl,
    'description': description,
    'category': category,
    'tags': tags,
    'isMature': isMature,
    'isCompleted': isCompleted,
    'isDraft': isDraft,
    'readCount': readCount,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory BookModel.fromMap(Map<String, dynamic> data, String id) => BookModel(
    id: id,
    writerId: data['writerId'] ?? '',
    writerNickname: data['writerNickname'] ?? '',
    title: data['title'] ?? '',
    coverImageUrl: data['coverImageUrl'] ?? '',
    description: data['description'] ?? '',
    category: data['category'] ?? '',
    tags: List<String>.from(data['tags'] ?? []),
    isMature: data['isMature'] ?? false,
    isCompleted: data['isCompleted'] ?? false,
    isDraft: data['isDraft'] ?? false,
    readCount: data['readCount'] ?? 0,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
