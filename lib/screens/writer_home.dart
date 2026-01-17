// Writer home screen: Wattpad-style UI
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';

const List<String> _categories = [
  'Fiction',
  'Non-Fiction',
  'Romance',
  'Fantasy',
  'Mystery',
  'Thriller',
  'Sci-Fi',
  'Horror',
  'Adventure',
  'Poetry',
  'Other',
];

// Dark theme colors
const _darkBg = Color(0xFF121212);
const _darkCard = Color(0xFF1E1E1E);
const _darkText = Colors.white;
const _darkTextSecondary = Color(0xFFAAAAAA);
const _accentColor = Color(0xFF00BFA5); // Teal/Light Turquoise

Widget _buildBookCover(
  String coverImageUrl, {
  double? width,
  double? height,
  BoxFit? fit,
}) {
  if (coverImageUrl.isEmpty) {
    return Container(
      width: width ?? 80,
      height: height ?? 110,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.book, size: 32, color: Colors.white54),
    );
  }
  try {
    if (coverImageUrl.startsWith('data:')) {
      final uri = Uri.parse(coverImageUrl);
      final data = uri.data;
      if (data != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            data.contentAsBytes(),
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
          ),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        coverImageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width ?? 80,
          height: height ?? 110,
          color: Colors.grey.shade800,
          child: const Icon(Icons.broken_image, color: Colors.white54),
        ),
      ),
    );
  } catch (_) {
    return Container(
      width: width ?? 80,
      height: height ?? 110,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.broken_image, size: 32, color: Colors.white54),
    );
  }
}

// ==================== WRITER HOME ====================
class WriterHome extends StatefulWidget {
  const WriterHome({Key? key}) : super(key: key);
  @override
  State<WriterHome> createState() => _WriterHomeState();
}

class _WriterHomeState extends State<WriterHome> {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();
  BookModel? _currentBook;
  List<BookModel> _allBooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final user = authService.getCurrentUser();
    if (user == null) return;
    final books = await firestoreService.getBooksByWriter(user.uid);
    if (mounted) {
      setState(() {
        _allBooks = books;
        _currentBook = books.isNotEmpty ? books.first : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.getCurrentUser();
    final publishedBooks = _allBooks.where((b) => !b.isDraft).toList();
    final draftBooks = _allBooks.where((b) => b.isDraft).toList();
    
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _darkBg,
        appBarTheme: const AppBarTheme(backgroundColor: _darkBg, elevation: 0),
      ),
      child: Scaffold(
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Write',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProfilePage(authService: authService),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '@${user?.displayName ?? user?.email?.split('@').first ?? 'User'}',
                                    style: const TextStyle(
                                      color: _darkTextSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade700,
                                    child: const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Create new story button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: () => _openCreateStory(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Create New Story'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Published Stories Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.public, color: _accentColor, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Published Stories',
                              style: TextStyle(
                                color: _darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${publishedBooks.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (publishedBooks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Center(
                            child: Text(
                              'No published stories yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: publishedBooks.length,
                            itemBuilder: (context, index) {
                              final book = publishedBooks[index];
                              return _buildBookCard(book);
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Draft Stories Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Drafts',
                              style: TextStyle(
                                color: _darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${draftBooks.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (draftBooks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Center(
                            child: Text(
                              'No drafts',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: draftBooks.length,
                            itemBuilder: (context, index) {
                              final book = draftBooks[index];
                              return _buildBookCard(book, isDraft: true);
                            },
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBookCard(BookModel book, {bool isDraft = false}) {
    return GestureDetector(
      onTap: () => _openEditStory(book),
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildBookCover(
                  book.coverImageUrl,
                  width: 120,
                  height: 140,
                ),
                if (isDraft)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DRAFT',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _darkText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select a story',
              style: TextStyle(
                color: _darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._allBooks.map(
            (book) => ListTile(
              leading: _buildBookCover(
                book.coverImageUrl,
                width: 40,
                height: 55,
              ),
              title: Text(book.title, style: const TextStyle(color: _darkText)),
              subtitle: Text(
                book.category,
                style: const TextStyle(color: _darkTextSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openEditStory(book);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStoryPage(
          authService: authService,
          firestoreService: firestoreService,
          onCreated: (book) {
            _loadBooks();
            _openEditStory(book);
          },
        ),
      ),
    );
  }

  void _openEditStory(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStoryPage(
          book: book,
          firestoreService: firestoreService,
          onUpdated: () => _loadBooks(),
        ),
      ),
    );
  }
}

// ==================== CREATE STORY PAGE ====================
class CreateStoryPage extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;
  final Function(BookModel) onCreated;

  const CreateStoryPage({
    Key? key,
    required this.authService,
    required this.firestoreService,
    required this.onCreated,
  }) : super(key: key);
  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  Uint8List? _coverImage;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _coverImage = bytes);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final user = widget.authService.getCurrentUser();
      if (user == null) throw Exception('Not signed in');

      String coverData = '';
      if (_coverImage != null) {
        final original = img.decodeImage(_coverImage!);
        if (original != null) {
          final resized = img.copyResize(original, width: 400);
          final bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 60));
          coverData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

      final bookId = await widget.firestoreService.createBook(
        user.uid,
        _titleController.text.trim(),
        coverData,
        description: _descController.text.trim(),
        category: 'Fiction',
        tags: [],
        isMature: false,
        isCompleted: false,
        isDraft: true,
      );

      // Fetch the created book
      final books = await widget.firestoreService.getBooksByWriter(user.uid);
      final createdBook = books.firstWhere(
        (b) => b.id == bookId,
        orElse: () => books.first,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(createdBook);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _darkBg,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Add Story Info'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Skip',
                style: TextStyle(color: _darkTextSecondary),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover picker
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: _coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_coverImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: _darkTextSecondary,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add a cover',
                              style: TextStyle(
                                color: _darkTextSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextField(
                controller: _titleController,
                style: const TextStyle(color: _darkText),
                decoration: const InputDecoration(
                  hintText: 'Story Title',
                  hintStyle: TextStyle(color: _darkTextSecondary),
                  border: InputBorder.none,
                ),
              ),
              Divider(color: Colors.grey.shade800),

              // Description
              TextField(
                controller: _descController,
                style: const TextStyle(color: _darkText),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Give a description of your story',
                  hintStyle: TextStyle(color: _darkTextSecondary),
                  border: InputBorder.none,
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Story'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== EDIT STORY PAGE ====================
class EditStoryPage extends StatefulWidget {
  final BookModel book;
  final FirestoreService firestoreService;
  final VoidCallback onUpdated;

  const EditStoryPage({
    Key? key,
    required this.book,
    required this.firestoreService,
    required this.onUpdated,
  }) : super(key: key);
  @override
  State<EditStoryPage> createState() => _EditStoryPageState();
}

class _EditStoryPageState extends State<EditStoryPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  late String _category;
  late bool _isMature;
  late bool _isCompleted;
  Uint8List? _newCover;
  List<dynamic> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _descController = TextEditingController(text: widget.book.description);
    _tagsController = TextEditingController(text: widget.book.tags.join(', '));
    _category = widget.book.category.isNotEmpty
        ? widget.book.category
        : _categories.first;
    _isMature = widget.book.isMature;
    _isCompleted = widget.book.isCompleted;
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final chapters = await widget.firestoreService.getChaptersByBook(
      widget.book.id,
    );
    if (mounted)
      setState(() {
        _chapters = chapters;
        _loading = false;
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _newCover = bytes);
    }
  }

  Future<void> _save() async {
    String? coverData;
    if (_newCover != null) {
      final original = img.decodeImage(_newCover!);
      if (original != null) {
        final resized = img.copyResize(original, width: 400);
        final bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 60));
        coverData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    }

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await widget.firestoreService.updateBookDetails(
      widget.book.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      tags: tags,
      isMature: _isMature,
      isCompleted: _isCompleted,
      coverImageUrl: coverData,
    );

    widget.onUpdated();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  void _addPart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartEditorPage(
          bookId: widget.book.id,
          firestoreService: widget.firestoreService,
          chapterNumber: _chapters.length + 1,
          onSaved: () => _loadChapters(),
        ),
      ),
    );
  }

  void _editPart(dynamic chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartEditorPage(
          bookId: widget.book.id,
          firestoreService: widget.firestoreService,
          chapter: chapter,
          chapterNumber: chapter.chapterNumber,
          onSaved: () => _loadChapters(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _darkBg,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Edit Story'),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: _accentColor)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: _pickCover,
                        child: Container(
                          width: 80,
                          height: 110,
                          decoration: BoxDecoration(
                            color: _darkCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: _newCover != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _newCover!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : widget.book.coverImageUrl.isNotEmpty
                              ? _buildBookCover(
                                  widget.book.coverImageUrl,
                                  width: 80,
                                  height: 110,
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: _darkTextSecondary,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add a cover',
                                      style: TextStyle(
                                        color: _darkTextSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    // Form fields
                    _buildField('Title *', _titleController),
                    _buildField('Description *', _descController, maxLines: 3),

                    // Category
                    ListTile(
                      title: const Text(
                        'Category *',
                        style: TextStyle(color: _darkText),
                      ),
                      trailing: DropdownButton<String>(
                        value: _category,
                        dropdownColor: _darkCard,
                        style: const TextStyle(color: _darkTextSecondary),
                        underline: const SizedBox(),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _category = v);
                        },
                      ),
                    ),
                    Divider(color: Colors.grey.shade800, height: 1),

                    _buildField(
                      'Tags',
                      _tagsController,
                      hint: 'Adding tags helps readers find your story!',
                    ),

                    // Mature toggle
                    SwitchListTile(
                      title: const Text(
                        'Mature',
                        style: TextStyle(color: _darkText),
                      ),
                      subtitle: const Text(
                        'Your story is appropriate for all audiences.',
                        style: TextStyle(
                          color: _darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: _isMature,
                      activeColor: _accentColor,
                      onChanged: (v) => setState(() => _isMature = v),
                    ),
                    Divider(color: Colors.grey.shade800, height: 1),

                    // Completed toggle
                    SwitchListTile(
                      title: const Text(
                        'Completed',
                        style: TextStyle(color: _darkText),
                      ),
                      value: _isCompleted,
                      activeColor: _accentColor,
                      onChanged: (v) => setState(() => _isCompleted = v),
                    ),
                    Divider(color: Colors.grey.shade800, height: 1),

                    // Table of contents
                    Container(
                      color: Colors.grey.shade900,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Table of contents',
                            style: TextStyle(
                              color: _darkText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.settings,
                            color: _darkTextSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    // Chapters list
                    if (_chapters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No parts yet',
                          style: TextStyle(color: _darkTextSecondary),
                        ),
                      )
                    else
                      ...(_chapters.map(
                        (ch) => ListTile(
                          title: Text(
                            ch.title.isEmpty
                                ? 'Part ${ch.chapterNumber}'
                                : ch.title,
                            style: const TextStyle(color: _darkText),
                          ),
                          subtitle: Text(
                            'Part ${ch.chapterNumber}',
                            style: const TextStyle(
                              color: _darkTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _darkTextSecondary,
                          ),
                          onTap: () => _editPart(ch),
                        ),
                      )),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addPart,
              icon: const Icon(Icons.add),
              label: const Text('Add a Part'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkCard,
                foregroundColor: _darkText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(label, style: const TextStyle(color: _darkText)),
          trailing: const Icon(Icons.chevron_right, color: _darkTextSecondary),
          onTap: () => _showFieldEditor(label, controller, maxLines: maxLines),
        ),
        Divider(color: Colors.grey.shade800, height: 1),
      ],
    );
  }

  void _showFieldEditor(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _darkBg,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: maxLines,
                style: const TextStyle(color: _darkText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PART EDITOR PAGE ====================
class PartEditorPage extends StatefulWidget {
  final String bookId;
  final FirestoreService firestoreService;
  final dynamic chapter;
  final int chapterNumber;
  final VoidCallback onSaved;

  const PartEditorPage({
    Key? key,
    required this.bookId,
    required this.firestoreService,
    this.chapter,
    required this.chapterNumber,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<PartEditorPage> createState() => _PartEditorPageState();
}

class _PartEditorPageState extends State<PartEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chapter?.title ?? '');
    _contentController = TextEditingController(
      text: widget.chapter?.content ?? '',
    );
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.chapter == null) {
        await widget.firestoreService.createChapter(
          widget.bookId,
          widget.chapterNumber,
          _titleController.text.trim(),
          _contentController.text.trim(),
        );
      } else {
        await widget.firestoreService.updateChapter(
          widget.chapter.id,
          _titleController.text.trim(),
          _contentController.text.trim(),
        );
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Published!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Toggle formatting on selected text (wrap/unwrap with markers)
  void _toggleFormat(String startTag, String endTag) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid || selection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select some text first'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);

    String newText;
    int newStart, newEnd;

    // Check if already formatted - remove formatting
    if (selectedText.startsWith(startTag) && selectedText.endsWith(endTag)) {
      // Remove tags
      final unformatted = selectedText.substring(
        startTag.length,
        selectedText.length - endTag.length,
      );
      newText = text.substring(0, start) + unformatted + text.substring(end);
      newStart = start;
      newEnd = start + unformatted.length;
    } else {
      // Add tags
      final formatted = '$startTag$selectedText$endTag';
      newText = text.substring(0, start) + formatted + text.substring(end);
      newStart = start;
      newEnd = start + formatted.length;
    }

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newStart, extentOffset: newEnd),
    );
  }

  void _toggleBold() => _toggleFormat('**', '**');
  void _toggleItalic() => _toggleFormat('_', '_');
  void _toggleUnderline() => _toggleFormat('<u>', '</u>');

  // Parse text and build formatted TextSpans
  List<TextSpan> _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(r'\*\*(.+?)\*\*|_(.+?)_|<u>(.+?)</u>');
    
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add plain text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      
      // Determine formatting type and add styled span
      if (match.group(1) != null) {
        // Bold **text**
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold, color: _darkText),
        ));
      } else if (match.group(2) != null) {
        // Italic _text_
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic, color: _darkText),
        ));
      } else if (match.group(3) != null) {
        // Underline <u>text</u>
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(decoration: TextDecoration.underline, color: _darkText),
        ));
      }
      
      lastEnd = match.end;
    }
    
    // Add remaining plain text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    
    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _darkBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: DropdownButton<int>(
            value: widget.chapterNumber,
            dropdownColor: _darkCard,
            style: const TextStyle(color: _darkText),
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: widget.chapterNumber,
                child: Text('Part ${widget.chapterNumber}'),
              ),
            ],
            onChanged: (_) {},
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _publish,
              child: Text(
                'Publish',
                style: TextStyle(
                  color: _saving ? _darkTextSecondary : _darkText,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Formatting toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _darkCard,
                border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FormatButton(
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    onPressed: _toggleBold,
                  ),
                  const SizedBox(width: 16),
                  _FormatButton(
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    onPressed: _toggleItalic,
                  ),
                  const SizedBox(width: 16),
                  _FormatButton(
                    icon: Icons.format_underline,
                    tooltip: 'Underline',
                    onPressed: _toggleUnderline,
                  ),
                ],
              ),
            ),

            // Drag handle indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Part title',
                        hintStyle: TextStyle(color: Color(0xFF555555)),
                        border: InputBorder.none,
                      ),
                    ),
                    Divider(color: Colors.grey.shade800),
                    
                    const SizedBox(height: 16),
                    
                    // Formatted preview card (tap to edit)
                    GestureDetector(
                      onTap: _showContentEditor,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: _contentController.text.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tap here to write your story...',
                                  style: TextStyle(color: Color(0xFF555555), fontSize: 16),
                                ),
                              )
                            : RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  style: const TextStyle(color: _darkText, fontSize: 16, height: 1.6),
                                  children: _buildFormattedText(_contentController.text),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _FormatButton(icon: Icons.format_bold, tooltip: 'Bold', onPressed: () { _toggleBold(); Navigator.pop(ctx); _showContentEditor(); }),
                    const SizedBox(width: 8),
                    _FormatButton(icon: Icons.format_italic, tooltip: 'Italic', onPressed: () { _toggleItalic(); Navigator.pop(ctx); _showContentEditor(); }),
                    const SizedBox(width: 8),
                    _FormatButton(icon: Icons.format_underline, tooltip: 'Underline', onPressed: () { _toggleUnderline(); Navigator.pop(ctx); _showContentEditor(); }),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('Done', style: TextStyle(color: _accentColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 12,
              style: const TextStyle(color: _darkText, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Write your story here...',
                hintStyle: const TextStyle(color: Color(0xFF555555)),
                filled: true,
                fillColor: _darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Format button widget
class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _darkText, size: 22),
        ),
      ),
    );
  }
}

// ==================== PROFILE PAGE ====================
class ProfilePage extends StatefulWidget {
  final AuthService authService;
  const ProfilePage({Key? key, required this.authService}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final user = widget.authService.getCurrentUser();
  final _nicknameController = TextEditingController();
  bool _editingNickname = false;
  bool _savingNickname = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = user?.displayName ?? '';
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _updateNickname() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname cannot be empty')),
      );
      return;
    }
    setState(() => _savingNickname = true);
    try {
      await user?.updateDisplayName(_nicknameController.text.trim());
      await user?.reload();
      setState(() {
        _editingNickname = false;
        _savingNickname = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _savingNickname = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating nickname: $e')),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool loading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _darkCard,
          title: const Text('Change Password', style: TextStyle(color: _darkText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  style: const TextStyle(color: _darkText),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(color: _darkTextSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _accentColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                        color: _darkTextSecondary,
                      ),
                      onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  style: const TextStyle(color: _darkText),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(color: _darkTextSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _accentColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: _darkTextSecondary,
                      ),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: _darkText),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(color: _darkTextSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _accentColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: _darkTextSecondary,
                      ),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (oldPasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New passwords do not match')),
                        );
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters')),
                        );
                        return;
                      }

                      setDialogState(() => loading = true);
                      try {
                        // Re-authenticate user with old password
                        final credential = EmailAuthProvider.credential(
                          email: user?.email ?? '',
                          password: oldPasswordController.text,
                        );
                        await user?.reauthenticateWithCredential(credential);
                        
                        // Update password
                        await user?.updatePassword(newPasswordController.text);
                        
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password changed successfully')),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => loading = false);
                        String message = 'Error changing password';
                        if (e.code == 'wrong-password') {
                          message = 'Current password is incorrect';
                        } else if (e.code == 'weak-password') {
                          message = 'New password is too weak';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      } catch (e) {
                        setDialogState(() => loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg)
          : ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.grey.shade100),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode ? _darkBg : Colors.white,
          foregroundColor: isDarkMode ? _darkText : Colors.black,
          title: const Text('Profile'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      child: Icon(
                        Icons.person,
                        size: 56,
                        color: isDarkMode ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nickname (editable)
                    if (_editingNickname)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _nicknameController,
                              style: TextStyle(
                                color: isDarkMode ? _darkText : Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _accentColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_savingNickname)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: _updateNickname,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _editingNickname = false;
                                  _nicknameController.text = user?.displayName ?? '';
                                });
                              },
                            ),
                          ],
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _editingNickname = true),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.displayName ?? 'Set Nickname',
                              style: TextStyle(
                                color: isDarkMode ? _darkText : Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: isDarkMode ? _darkTextSecondary : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Email (non-editable)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: isDarkMode ? _darkTextSecondary : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Settings Section
              Text(
                'Settings',
                style: TextStyle(
                  color: isDarkMode ? _darkTextSecondary : Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Theme Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? _darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
                  ),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (val) => themeService.setDarkMode(val),
                    activeColor: _accentColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Change Password
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? _darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.lock_outline,
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                  title: Text(
                    'Change Password',
                    style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDarkMode ? _darkTextSecondary : Colors.grey,
                  ),
                  onTap: _showChangePasswordDialog,
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.authService.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
