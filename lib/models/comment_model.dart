import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String bookId;
  final String? chapterId;
  final String userId;
  final String userNickname;
  final String message;
  final String? selectedText; // For inline comments
  final int? textStartIndex; // Position in chapter content
  final int? textEndIndex;
  final String? parentCommentId; // For replies
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.userId,
    this.userNickname = '',
    required this.message,
    this.selectedText,
    this.textStartIndex,
    this.textEndIndex,
    this.parentCommentId,
    required this.createdAt,
  });

  bool get isInlineComment => selectedText != null && selectedText!.isNotEmpty;
  bool get isReply => parentCommentId != null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'chapterId': chapterId,
    'userId': userId,
    'userNickname': userNickname,
    'message': message,
    'selectedText': selectedText,
    'textStartIndex': textStartIndex,
    'textEndIndex': textEndIndex,
    'parentCommentId': parentCommentId,
    'createdAt': createdAt,
  };

  factory CommentModel.fromMap(Map<String, dynamic> data, String id) =>
      CommentModel(
        id: id,
        bookId: data['bookId'] ?? '',
        chapterId: data['chapterId'],
        userId: data['userId'] ?? '',
        userNickname: data['userNickname'] ?? '',
        message: data['message'] ?? '',
        selectedText: data['selectedText'],
        textStartIndex: data['textStartIndex'],
        textEndIndex: data['textEndIndex'],
        parentCommentId: data['parentCommentId'],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
