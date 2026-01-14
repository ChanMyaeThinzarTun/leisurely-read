import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin', 'writer', 'reader'
  final bool isApproved;
  final DateTime? bannedUntil;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.isApproved,
    this.bannedUntil,
    required this.createdAt,
  });

  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'role': role,
    'isApproved': isApproved,
    'bannedUntil': bannedUntil,
    'createdAt': createdAt,
  };

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) => UserModel(
    uid: uid,
    email: data['email'] ?? '',
    role: data['role'] ?? 'reader',
    isApproved: data['isApproved'] ?? false,
    bannedUntil: data['bannedUntil'] != null
        ? (data['bannedUntil'] as Timestamp).toDate()
        : null,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
