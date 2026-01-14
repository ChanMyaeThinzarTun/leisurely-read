import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterModel {
  final String id;
  final String bookId;
  final int chapterNumber;
  final String title;
  final String content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChapterModel({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'chapterNumber': chapterNumber,
    'title': title,
    'content': content,
    'imageUrls': imageUrls,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory ChapterModel.fromMap(Map<String, dynamic> data, String id) =>
      ChapterModel(
        id: id,
        bookId: data['bookId'] ?? '',
        chapterNumber: data['chapterNumber'] ?? 0,
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
