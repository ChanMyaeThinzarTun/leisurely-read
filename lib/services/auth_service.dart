import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants for writer signup code
  static const String writerSignupCode = '123456'; // Default code for Phase 1
  static const String adminEmail = 'admin.leisurelyread@gmail.com';

  Future<void> _ensureUserDocument(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) return;

    final isAdmin = (user.email ?? '').toLowerCase() == adminEmail;
    await docRef.set({
      'email': user.email ?? '',
      'role': isAdmin ? 'admin' : 'reader',
      'isApproved': true,
      'bannedUntil': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign up Reader
  Future<User?> signUpReader(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Add to Firestore
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': 'reader',
      'isApproved': true,
      'bannedUntil': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred.user;
  }

  // Sign up Writer (requires admin approval code)
  Future<User?> signUpWriter(String email, String password, String code) async {
    if (code != writerSignupCode) {
      throw Exception('Invalid writer signup code');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Add to Firestore with isApproved = false
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': 'writer',
      'isApproved': false,
      'bannedUntil': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred.user;
  }

  // Create Admin Account (one-time setup)
  Future<User?> createAdminAccount(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Add to Firestore
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': 'admin',
      'isApproved': true,
      'bannedUntil': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred.user;
  }

  // Login
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserDocument(cred.user!);
    return cred.user;
  }

  // Get user data
  Future<Map<String, dynamic>> getUserData(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    var doc = await docRef.get();

    // If missing, create a default profile based on current user email
    if (!doc.exists) {
      final current = _auth.currentUser;
      if (current != null) {
        await _ensureUserDocument(current);
        doc = await docRef.get();
      }
    }

    return doc.data() ?? {};
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No user logged in');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() => _auth.currentUser;
}
