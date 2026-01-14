import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';

class WriterHome extends StatefulWidget {
  const WriterHome({super.key});

  @override
  State<WriterHome> createState() => _WriterHomeState();
}

class _WriterHomeState extends State<WriterHome> {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

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
    final currentUser = authService.getCurrentUser();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writer Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.lock), onPressed: changePassword),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: FutureBuilder<List<BookModel>>(
        future: firestoreService.getBooksByWriter(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data ?? [];
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Books',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (books.isEmpty)
                      const Center(
                        child: Text('No books yet. Create one to get started!'),
                      )
                    else
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                          return _BookCard(
                            book: book,
                            firestoreService: firestoreService,
                            onRefresh: () => setState(() {}),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBookDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context) {
    final titleController = TextEditingController();
    final coverUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Book Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: coverUrlController,
              decoration: const InputDecoration(
                labelText: 'Cover Image URL',
                hintText: 'https://example.com/cover.jpg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  coverUrlController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final currentUser = authService.getCurrentUser();
              await firestoreService.createBook(
                currentUser!.uid,
                titleController.text,
                coverUrlController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  final FirestoreService firestoreService;
  final VoidCallback onRefresh;

  const _BookCard({
    required this.book,
    required this.firestoreService,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _BookDetailScreen(
            book: book,
            firestoreService: firestoreService,
            onRefresh: onRefresh,
          ),
        ),
      ),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                book.coverImageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.book),
                ),
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

class _BookDetailScreen extends StatefulWidget {
  final BookModel book;
  final FirestoreService firestoreService;
  final VoidCallback onRefresh;

  const _BookDetailScreen({
    required this.book,
    required this.firestoreService,
    required this.onRefresh,
  });

  @override
  State<_BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<_BookDetailScreen> {
  late Future<List<ChapterModel>> chapters;

  @override
  void initState() {
    super.initState();
    chapters = widget.firestoreService.getChaptersByBook(widget.book.id);
  }

  void refreshChapters() {
    setState(() {
      chapters = widget.firestoreService.getChaptersByBook(widget.book.id);
    });
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Image.network(
                widget.book.coverImageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chapters (${chapterList.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (chapterList.isEmpty)
                const Center(child: Text('No chapters yet'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chapterList.length,
                  itemBuilder: (context, index) {
                    final chapter = chapterList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          'Chapter ${chapter.chapterNumber}: ${chapter.title}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Chapter'),
                                content: const Text('Are you sure?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await widget.firestoreService.deleteChapter(
                                chapter.id,
                              );
                              refreshChapters();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChapterDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateChapterDialog(BuildContext context) {
    final chapterNumberController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Chapter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: chapterNumberController,
                decoration: const InputDecoration(labelText: 'Chapter Number'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Chapter Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Chapter Content',
                  hintText: 'Write your chapter here...',
                ),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (chapterNumberController.text.isEmpty ||
                  titleController.text.isEmpty ||
                  contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              await widget.firestoreService.createChapter(
                widget.book.id,
                int.parse(chapterNumberController.text),
                titleController.text,
                contentController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                refreshChapters();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chapter created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
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
