import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String writerId;
  final String title;
  final String coverImageUrl;
  final String description;
  final String category;
  final List<String> tags;
  final bool isMature;
  final bool isCompleted;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.writerId,
    required this.title,
    required this.coverImageUrl,
    this.description = '',
    this.category = '',
    this.tags = const [],
    this.isMature = false,
    this.isCompleted = false,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'writerId': writerId,
    'title': title,
    'coverImageUrl': coverImageUrl,
    'description': description,
    'category': category,
    'tags': tags,
    'isMature': isMature,
    'isCompleted': isCompleted,
    'isDraft': isDraft,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory BookModel.fromMap(Map<String, dynamic> data, String id) => BookModel(
    id: id,
    writerId: data['writerId'] ?? '',
    title: data['title'] ?? '',
    coverImageUrl: data['coverImageUrl'] ?? '',
    description: data['description'] ?? '',
    category: data['category'] ?? '',
    tags: List<String>.from(data['tags'] ?? []),
    isMature: data['isMature'] ?? false,
    isCompleted: data['isCompleted'] ?? false,
    isDraft: data['isDraft'] ?? false,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
