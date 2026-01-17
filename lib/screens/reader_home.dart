import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';

// Helper widget to display book cover (base64 or placeholder)
Widget _buildBookCover(
  String coverImageUrl, {
  double? width,
  double? height,
  BoxFit? fit,
}) {
  if (coverImageUrl.isEmpty) {
    // No image - show placeholder
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.book, size: 40, color: Colors.grey),
    );
  } else if (coverImageUrl.startsWith('data:image')) {
    // Base64 image
    try {
      final base64String = coverImageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.book),
        ),
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.book),
      );
    }
  } else {
    // Fallback for old URLs
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.book),
    );
  }
}

class ReaderHome extends StatefulWidget {
  const ReaderHome({super.key});

  @override
  State<ReaderHome> createState() => _ReaderHomeState();
}

class _ReaderHomeState extends State<ReaderHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void logout() async {
    await authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void changePassword() {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(authService: authService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leisurely Read'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Library'),
            Tab(text: 'Notifications'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.lock), onPressed: changePassword),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BrowseTab(firestoreService: firestoreService),
          _LibraryTab(
            firestoreService: firestoreService,
            userId: authService.getCurrentUser()!.uid,
          ),
          _NotificationsTab(
            firestoreService: firestoreService,
            userId: authService.getCurrentUser()!.uid,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _BrowseTab extends StatefulWidget {
  final FirestoreService firestoreService;
  const _BrowseTab({required this.firestoreService});

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  late Future<List<BookModel>> books;

  @override
  void initState() {
    super.initState();
    books = widget.firestoreService.getAllBooks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookModel>>(
      future: books,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookList = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Browse Books',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (bookList.isEmpty)
              const Center(child: Text('No books available'))
            else
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: bookList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final book = bookList[index];
                  return _BookBrowseCard(
                    book: book,
                    firestoreService: widget.firestoreService,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _BookBrowseCard extends StatelessWidget {
  final BookModel book;
  final FirestoreService firestoreService;

  const _BookBrowseCard({required this.book, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              _BookReadScreen(book: book, firestoreService: firestoreService),
        ),
      ),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Expanded(
              child: _buildBookCover(
                book.coverImageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (book.category != null && book.category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      book.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (book.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: book.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (book.isMature == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        'Mature',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookReadScreen extends StatefulWidget {
  final BookModel book;
  final FirestoreService firestoreService;

  const _BookReadScreen({required this.book, required this.firestoreService});

  @override
  State<_BookReadScreen> createState() => _BookReadScreenState();
}

class _BookReadScreenState extends State<_BookReadScreen> {
  late Future<List<ChapterModel>> chapters;
  int selectedChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    chapters = widget.firestoreService.getChaptersByBook(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: FutureBuilder<List<ChapterModel>>(
        future: chapters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chapterList = snapshot.data ?? [];
          if (chapterList.isEmpty) {
            return Column(
              children: [
                // Book metadata even if no chapters
                if (widget.book.description != null &&
                    widget.book.description!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.book.isMature == true)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'MATURE CONTENT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Text(
                          'About this book',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.book.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (widget.book.category != null &&
                            widget.book.category!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.book.category!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.book.isCompleted == true) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (widget.book.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.book.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                const Expanded(
                  child: Center(child: Text('No chapters available')),
                ),
              ],
            );
          }

          return Column(
            children: [
              // Book metadata section
              if (widget.book.description != null &&
                  widget.book.description!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.book.isMature == true)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'MATURE CONTENT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text(
                        'About this book',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (widget.book.category != null &&
                          widget.book.category!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.book.category!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.book.isCompleted == true) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (widget.book.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.book.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              // Chapter selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: List.generate(
                    chapterList.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('Ch ${chapterList[index].chapterNumber}'),
                        selected: selectedChapterIndex == index,
                        onSelected: (selected) {
                          setState(() => selectedChapterIndex = index);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Chapter content
              Expanded(
                child: _ChapterContentView(
                  chapter: chapterList[selectedChapterIndex],
                  firestoreService: widget.firestoreService,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChapterContentView extends StatefulWidget {
  final ChapterModel chapter;
  final FirestoreService firestoreService;

  const _ChapterContentView({
    required this.chapter,
    required this.firestoreService,
  });

  @override
  State<_ChapterContentView> createState() => _ChapterContentViewState();
}

class _ChapterContentViewState extends State<_ChapterContentView> {
  late Future<int> voteCount;
  late Future<bool> hasVoted;
  late Future<List<CommentModel>> comments;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    voteCount = widget.firestoreService.getVoteCount(widget.chapter.id);
    hasVoted = widget.firestoreService.hasUserVoted(
      widget.chapter.id,
      currentUser!.uid,
    );
    comments = widget.firestoreService.getCommentsByChapter(widget.chapter.id);
  }

  Widget _buildFormattedContent(String content) {
    try {
      // Try to parse as Quill delta JSON
      final deltaJson = jsonDecode(content) as List;
      final spans = <TextSpan>[];

      for (var op in deltaJson) {
        if (op is Map && op.containsKey('insert')) {
          final text = op['insert'].toString();
          final attributes = op['attributes'] as Map<String, dynamic>?;

          TextStyle style = const TextStyle(fontSize: 16, color: Colors.black);

          if (attributes != null) {
            if (attributes['bold'] == true) {
              style = style.copyWith(fontWeight: FontWeight.bold);
            }
            if (attributes['italic'] == true) {
              style = style.copyWith(fontStyle: FontStyle.italic);
            }
            if (attributes['underline'] == true) {
              style = style.copyWith(decoration: TextDecoration.underline);
            }
          }

          spans.add(TextSpan(text: text, style: style));
        }
      }

      return Text.rich(TextSpan(children: spans));
    } catch (e) {
      // If parsing fails, display as plain text
      return Text(content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chapter ${widget.chapter.chapterNumber}: ${widget.chapter.title}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildFormattedContent(widget.chapter.content),
          const SizedBox(height: 24),
          // Vote section
          Row(
            children: [
              FutureBuilder<bool>(
                future: hasVoted,
                builder: (context, snapshot) {
                  final voted = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      color: voted ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () async {
                      await widget.firestoreService.addVote(
                        widget.chapter.id,
                        currentUser!.uid,
                      );
                      setState(() => _refreshData());
                    },
                  );
                },
              ),
              FutureBuilder<int>(
                future: voteCount,
                builder: (context, snapshot) {
                  return Text('${snapshot.data ?? 0} votes');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Comments section
          Text('Comments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FutureBuilder<List<CommentModel>>(
            future: comments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final commentList = snapshot.data ?? [];
              return Column(
                children: [
                  ...commentList.map(
                    (comment) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userId,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(comment.message),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Add comment section
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _showAddCommentDialog(context),
              ),
            ),
            readOnly: true,
            onTap: () => _showAddCommentDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAddCommentDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write your comment...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await widget.firestoreService.addComment(
                  widget.chapter.bookId,
                  currentUser!.uid,
                  controller.text,
                  chapterId: widget.chapter.id,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _refreshData());
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _LibraryTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final String userId;

  const _LibraryTab({required this.firestoreService, required this.userId});

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  late Future<List<BookModel>> libraryBooks;

  @override
  void initState() {
    super.initState();
    libraryBooks = widget.firestoreService.getReaderLibrary(widget.userId);
  }

  void refreshLibrary() {
    setState(() {
      libraryBooks = widget.firestoreService.getReaderLibrary(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookModel>>(
      future: libraryBooks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'My Library',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (books.isEmpty)
              const Center(child: Text('No books in your library yet'))
            else
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: books.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return _LibraryBookCard(
                    book: book,
                    firestoreService: widget.firestoreService,
                    userId: widget.userId,
                    onRefresh: refreshLibrary,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _LibraryBookCard extends StatelessWidget {
  final BookModel book;
  final FirestoreService firestoreService;
  final String userId;
  final VoidCallback onRefresh;

  const _LibraryBookCard({
    required this.book,
    required this.firestoreService,
    required this.userId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove from Library'),
            content: const Text('Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await firestoreService.removeBookFromLibrary(userId, book.id);
          onRefresh();
        }
      },
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Expanded(
              child: _buildBookCover(
                book.coverImageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final String userId;

  const _NotificationsTab({
    required this.firestoreService,
    required this.userId,
  });

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  late Future<List<NotificationModel>> notifications;

  @override
  void initState() {
    super.initState();
    notifications = widget.firestoreService.getUserNotifications(widget.userId);
  }

  void refreshNotifications() {
    setState(() {
      notifications = widget.firestoreService.getUserNotifications(
        widget.userId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationModel>>(
      future: notifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notificationList = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (notificationList.isEmpty)
              const Center(child: Text('No notifications'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notificationList.length,
                itemBuilder: (context, index) {
                  final notif = notificationList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: notif.read ? Colors.white : Colors.blue[50],
                    child: ListTile(
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.read
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notif.message),
                      trailing: notif.read
                          ? null
                          : Chip(
                              label: const Text('New'),
                              backgroundColor: Colors.blue,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                      onTap: () async {
                        if (!notif.read) {
                          await widget.firestoreService.markNotificationAsRead(
                            notif.id,
                          );
                          refreshNotifications();
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AuthService authService;
  const _ChangePasswordDialog({required this.authService});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool loading = false;

  void changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => loading = true);
    try {
      await widget.authService.changePassword(newPasswordController.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: newPasswordController,
            decoration: const InputDecoration(labelText: 'New Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: loading ? null : changePassword,
          child: loading
              ? const CircularProgressIndicator()
              : const Text('Change'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
