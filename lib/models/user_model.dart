import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String role; // 'admin', 'writer', 'reader'
  final bool isApproved;
  final DateTime? bannedUntil;
  final DateTime createdAt;
  final bool safeSearch; // Hide mature content

  UserModel({
    required this.uid,
    required this.email,
    this.nickname = '',
    required this.role,
    required this.isApproved,
    this.bannedUntil,
    required this.createdAt,
    this.safeSearch = true,
  });

  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  String get displayName =>
      nickname.isNotEmpty ? nickname : email.split('@').first;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'nickname': nickname,
    'role': role,
    'isApproved': isApproved,
    'bannedUntil': bannedUntil,
    'createdAt': createdAt,
    'safeSearch': safeSearch,
  };

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) => UserModel(
    uid: uid,
    email: data['email'] ?? '',
    nickname: data['nickname'] ?? '',
    role: data['role'] ?? 'reader',
    isApproved: data['isApproved'] ?? false,
    bannedUntil: data['bannedUntil'] != null
        ? (data['bannedUntil'] as Timestamp).toDate()
        : null,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    safeSearch: data['safeSearch'] ?? true,
  );
}
