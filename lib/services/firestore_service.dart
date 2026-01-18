import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USERS ====================

  Future<void> updateUserNickname(String userId, String nickname) async {
    await _firestore.collection('users').doc(userId).update({
      'nickname': nickname,
    });
  }

  Future<void> updateSafeSearch(String userId, bool safeSearch) async {
    await _firestore.collection('users').doc(userId).update({
      'safeSearch': safeSearch,
    });
  }

  Future<bool> getSafeSearch(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['safeSearch'] ?? true;
  }

  Future<void> banUser(String userId, DateTime bannedUntil) async {
    await _firestore.collection('users').doc(userId).update({
      'bannedUntil': bannedUntil,
    });
  }

  Future<void> unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'bannedUntil': null,
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> approveWriter(String writerId) async {
    await _firestore.collection('users').doc(writerId).update({
      'isApproved': true,
    });
  }

  Future<void> rejectWriter(String writerId) async {
    await _firestore.collection('users').doc(writerId).delete();
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> getUnapprovedWriters() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'writer')
        .where('isApproved', isEqualTo: false)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // ==================== BOOKS ====================

  Future<String> createBook(
    String writerId,
    String title,
    String coverImageUrl, {
    String description = '',
    String category = '',
    List<String> tags = const [],
    bool isMature = false,
    bool isCompleted = false,
    bool isDraft = false,
    String writerNickname = '',
  }) async {
    final docRef = await _firestore.collection('books').add({
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
      'readCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateBookCover(String bookId, String coverImageUrl) async {
    await _firestore.collection('books').doc(bookId).update({
      'coverImageUrl': coverImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookDetails(
    String bookId, {
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    bool? isMature,
    bool? isCompleted,
    String? coverImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    if (tags != null) updates['tags'] = tags;
    if (isMature != null) updates['isMature'] = isMature;
    if (isCompleted != null) updates['isCompleted'] = isCompleted;
    if (coverImageUrl != null) updates['coverImageUrl'] = coverImageUrl;

    await _firestore.collection('books').doc(bookId).update(updates);
  }

  Future<void> publishBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'isDraft': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unpublishBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'isDraft': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBook(String bookId) async {
    // Delete all chapters
    final chapters = await _firestore
        .collection('chapters')
        .where('bookId', isEqualTo: bookId)
        .get();
    for (var doc in chapters.docs) {
      await doc.reference.delete();
    }
    // Delete all comments on this book
    final comments = await _firestore
        .collection('comments')
        .where('bookId', isEqualTo: bookId)
        .get();
    for (var doc in comments.docs) {
      await doc.reference.delete();
    }
    // Delete the book
    await _firestore.collection('books').doc(bookId).delete();
  }

  Future<List<BookModel>> getAllBooks({bool safeSearch = true}) async {
    final snapshot = await _firestore
        .collection('books')
        .where('isDraft', isEqualTo: false)
        .get();
    var books = snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
    // Filter mature content if safe search is on
    if (safeSearch) {
      books = books.where((b) => !b.isMature).toList();
    }
    books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return books;
  }

  Future<List<BookModel>> getPublishedBooksByWriter(String writerId) async {
    final snapshot = await _firestore
        .collection('books')
        .where('writerId', isEqualTo: writerId)
        .where('isDraft', isEqualTo: false)
        .get();
    final books = snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
    books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return books;
  }

  Future<List<BookModel>> getBooksByWriter(String writerId) async {
    final snapshot = await _firestore
        .collection('books')
        .where('writerId', isEqualTo: writerId)
        .get();
    final books = snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
    // Sort in app to avoid requiring composite index
    books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return books;
  }

  Future<BookModel?> getBookById(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (!doc.exists) return null;
    return BookModel.fromMap(doc.data()!, doc.id);
  }

  // ==================== CHAPTERS ====================

  Future<String> createChapter(
    String bookId,
    int chapterNumber,
    String title,
    String content, {
    List<String>? imageUrls,
    bool isDraft = false,
  }) async {
    final docRef = await _firestore.collection('chapters').add({
      'bookId': bookId,
      'chapterNumber': chapterNumber,
      'title': title,
      'content': content,
      'imageUrls': imageUrls ?? [],
      'isDraft': isDraft,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateChapter(
    String chapterId,
    String title,
    String content, {
    List<String>? imageUrls,
    bool? isDraft,
  }) async {
    await _firestore.collection('chapters').doc(chapterId).update({
      'title': title,
      'content': content,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (isDraft != null) 'isDraft': isDraft,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChapter(String chapterId) async {
    // Delete all votes on this chapter
    final votes = await _firestore
        .collection('votes')
        .where('chapterId', isEqualTo: chapterId)
        .get();
    for (var doc in votes.docs) {
      await doc.reference.delete();
    }
    // Delete all comments on this chapter
    final comments = await _firestore
        .collection('comments')
        .where('chapterId', isEqualTo: chapterId)
        .get();
    for (var doc in comments.docs) {
      await doc.reference.delete();
    }
    // Delete the chapter
    await _firestore.collection('chapters').doc(chapterId).delete();
  }

  Future<List<ChapterModel>> getChaptersByBook(String bookId) async {
    final snapshot = await _firestore
        .collection('chapters')
        .where('bookId', isEqualTo: bookId)
        .get();
    final chapters = snapshot.docs
        .map((doc) => ChapterModel.fromMap(doc.data(), doc.id))
        .toList();
    // Sort in-app to avoid composite index requirement
    chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return chapters;
  }

  Future<ChapterModel?> getChapterById(String chapterId) async {
    final doc = await _firestore.collection('chapters').doc(chapterId).get();
    if (!doc.exists) return null;
    return ChapterModel.fromMap(doc.data()!, doc.id);
  }

  // ==================== COMMENTS ====================

  Future<String> addComment(
    String bookId,
    String userId,
    String message, {
    String? chapterId,
    String userNickname = '',
    String? selectedText,
    int? textStartIndex,
    int? textEndIndex,
    String? parentCommentId,
  }) async {
    final docRef = await _firestore.collection('comments').add({
      'bookId': bookId,
      'chapterId': chapterId,
      'userId': userId,
      'userNickname': userNickname,
      'message': message,
      'selectedText': selectedText,
      'textStartIndex': textStartIndex,
      'textEndIndex': textEndIndex,
      'parentCommentId': parentCommentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<List<CommentModel>> getCommentReplies(String parentCommentId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .get();
    final replies = snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .toList();
    // Sort in-app to avoid needing composite index
    replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return replies;
  }

  Future<List<CommentModel>> getInlineComments(String chapterId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('chapterId', isEqualTo: chapterId)
        .where('selectedText', isNull: false)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['selectedText'] != null)
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<CommentModel>> getCommentsByChapter(String chapterId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('chapterId', isEqualTo: chapterId)
        .get();
    // Filter out replies (comments with parentCommentId) and sort in-app
    final comments = snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .where((c) => c.parentCommentId == null || c.parentCommentId!.isEmpty)
        .toList();
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return comments;
  }

  Future<List<CommentModel>> getCommentsByBook(String bookId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==================== VOTES ====================

  Future<void> addVote(String chapterId, String userId) async {
    // Check if vote already exists - use document ID to avoid composite index
    final docId = '${chapterId}_$userId';
    final docRef = _firestore.collection('votes').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) {
      // Remove existing vote
      await docRef.delete();
    } else {
      // Add new vote
      await docRef.set({
        'chapterId': chapterId,
        'userId': userId,
        'voteValue': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<int> getVoteCount(String chapterId) async {
    final snapshot = await _firestore
        .collection('votes')
        .where('chapterId', isEqualTo: chapterId)
        .get();
    return snapshot.docs.length;
  }

  Future<bool> hasUserVoted(String chapterId, String userId) async {
    // Use document ID to check - avoids composite index
    final docId = '${chapterId}_$userId';
    final doc = await _firestore.collection('votes').doc(docId).get();
    return doc.exists;
  }

  // ==================== NOTIFICATIONS ====================

  Future<String> sendNotification(
    String userId,
    String title,
    String message,
    String type, // 'warning', 'info', 'alert'
  ) async {
    final docRef = await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> sendNotificationToAll(
    String title,
    String message,
    String type,
  ) async {
    final users = await getAllUsers();
    for (var user in users) {
      await sendNotification(user.uid, title, message, type);
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  // ==================== LIBRARY (Reader's Personal Library) ====================

  Future<void> addBookToLibrary(String userId, String bookId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(bookId)
        .set({'bookId': bookId, 'addedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeBookFromLibrary(String userId, String bookId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(bookId)
        .delete();
  }

  Future<List<BookModel>> getReaderLibrary(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .orderBy('addedAt', descending: true)
        .get();

    List<BookModel> books = [];
    for (var doc in snapshot.docs) {
      final bookId = doc['bookId'];
      final book = await getBookById(bookId);
      if (book != null) {
        books.add(book);
      }
    }
    return books;
  }

  Future<bool> isBookInLibrary(String userId, String bookId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(bookId)
        .get();
    return doc.exists;
  }

  // ==================== READING POSITION ====================

  Future<void> saveReadingPosition(
    String userId,
    String bookId,
    String chapterId,
    double scrollPosition,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(bookId)
        .update({
          'lastChapterId': chapterId,
          'scrollPosition': scrollPosition,
          'lastReadAt': FieldValue.serverTimestamp(),
        });
  }

  Future<Map<String, dynamic>?> getReadingPosition(
    String userId,
    String bookId,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(bookId)
        .get();
    if (doc.exists) {
      return {
        'lastChapterId': doc.data()?['lastChapterId'],
        'scrollPosition': doc.data()?['scrollPosition'] ?? 0.0,
      };
    }
    return null;
  }

  // ==================== SEARCH ====================

  Future<List<BookModel>> searchBooks(
    String query, {
    bool safeSearch = true,
  }) async {
    // Get all published books and filter locally
    final snapshot = await _firestore
        .collection('books')
        .where('isDraft', isEqualTo: false)
        .get();

    final queryLower = query.toLowerCase();
    var results = snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .where(
          (book) =>
              book.title.toLowerCase().contains(queryLower) ||
              book.writerNickname.toLowerCase().contains(queryLower) ||
              book.description.toLowerCase().contains(queryLower) ||
              book.tags.any((tag) => tag.toLowerCase().contains(queryLower)),
        )
        .toList();

    // Filter mature content if safe search is on
    if (safeSearch) {
      results = results.where((b) => !b.isMature).toList();
    }
    return results;
  }

  Future<List<UserModel>> searchWriters(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'writer')
        .where('isApproved', isEqualTo: true)
        .get();

    final queryLower = query.toLowerCase();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where(
          (user) =>
              user.nickname.toLowerCase().contains(queryLower) ||
              user.email.toLowerCase().contains(queryLower),
        )
        .toList();
  }

  // ==================== BOOK STATS ====================

  Future<void> incrementReadCount(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'readCount': FieldValue.increment(1),
    });
  }

  Future<int> getTotalVotesForBook(String bookId) async {
    final chapters = await getChaptersByBook(bookId);
    int totalVotes = 0;
    for (var chapter in chapters) {
      totalVotes += await getVoteCount(chapter.id);
    }
    return totalVotes;
  }

  Future<int> getChapterCount(String bookId) async {
    final snapshot = await _firestore
        .collection('chapters')
        .where('bookId', isEqualTo: bookId)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getCommentCount(String bookId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('bookId', isEqualTo: bookId)
        .get();
    return snapshot.docs.length;
  }
}
