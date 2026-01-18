import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

// Theme colors
const _darkBg = Color(0xFF121212);
const _darkCard = Color(0xFF1E1E1E);
const _darkText = Colors.white;
const _darkTextSecondary = Color(0xFFAAAAAA);
const _accentColor = Color(0xFF00BFA5); // Teal

String _formatNumber(int num) {
  if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
  if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
  return num.toString();
}

// Helper widget to display book cover (base64 or placeholder)
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
      child: Container(
        width: width ?? 80,
        height: height ?? 110,
        color: Colors.grey.shade800,
        child: const Icon(Icons.book, color: Colors.white54),
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

class ReaderHome extends StatefulWidget {
  const ReaderHome({super.key});

  @override
  State<ReaderHome> createState() => _ReaderHomeState();
}

class _ReaderHomeState extends State<ReaderHome> {
  int _currentIndex = 0;
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    final userId = authService.getCurrentUser()?.uid ?? '';

    final pages = [
      _BrowseTab(firestoreService: firestoreService, userId: userId),
      _SearchTab(firestoreService: firestoreService, userId: userId),
      _LibraryTab(firestoreService: firestoreService, userId: userId),
      _NotificationsTab(firestoreService: firestoreService, userId: userId),
      _ProfileTab(
        authService: authService,
        firestoreService: firestoreService,
        userId: userId,
      ),
    ];

    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: _darkBg,
              appBarTheme: const AppBarTheme(
                backgroundColor: _darkBg,
                elevation: 0,
              ),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.grey.shade100,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
              ),
            ),
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? _darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildNavItem(
                    1,
                    Icons.search_outlined,
                    Icons.search,
                    'Search',
                  ),
                  _buildNavItem(
                    2,
                    Icons.library_books_outlined,
                    Icons.library_books,
                    'Library',
                  ),
                  _buildNavItem(
                    3,
                    Icons.notifications_outlined,
                    Icons.notifications,
                    'Updates',
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_outline,
                    Icons.person,
                    'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final isDarkMode = themeService.isDarkMode;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected
                ? _accentColor
                : (isDarkMode ? _darkTextSecondary : Colors.grey),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? _accentColor
                  : (isDarkMode ? _darkTextSecondary : Colors.grey),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BROWSE TAB ====================
class _BrowseTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final String userId;
  const _BrowseTab({required this.firestoreService, required this.userId});

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  late Future<List<BookModel>> books;
  String _selectedCategory = 'All';
  bool _safeSearch = true;

  final List<String> _categories = [
    'All',
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
  ];

  @override
  void initState() {
    super.initState();
    _loadSafeSearch();
  }

  Future<void> _loadSafeSearch() async {
    final safe = await widget.firestoreService.getSafeSearch(widget.userId);
    setState(() {
      _safeSearch = safe;
      books = widget.firestoreService.getAllBooks(safeSearch: _safeSearch);
    });
  }

  void _refreshBooks() {
    setState(() {
      books = widget.firestoreService.getAllBooks(safeSearch: _safeSearch);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Browse',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) =>
                        setState(() => _selectedCategory = category),
                    selectedColor: _accentColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode ? _darkText : Colors.black),
                      fontSize: 12,
                    ),
                    backgroundColor: isDarkMode
                        ? _darkCard
                        : Colors.grey.shade200,
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<BookModel>>(
              future: books,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final allBooks = snapshot.data ?? [];
                final filteredBooks = allBooks.where((book) {
                  return _selectedCategory == 'All' ||
                      book.category == _selectedCategory;
                }).toList();

                if (filteredBooks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No books found',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshBooks(),
                  color: _accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return _BookListItem(
                        book: book,
                        firestoreService: widget.firestoreService,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  final BookModel book;
  final FirestoreService firestoreService;

  const _BookListItem({required this.book, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _BookDetailScreen(book: book, firestoreService: firestoreService),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildBookCover(
                book.coverImageUrl,
                width: 80,
                height: 110,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? _darkText : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: isDarkMode ? _darkTextSecondary : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatNumber(book.readCount),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: isDarkMode ? _darkTextSecondary : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      FutureBuilder<int>(
                        future: firestoreService.getTotalVotesForBook(book.id),
                        builder: (context, snapshot) => Text(
                          _formatNumber(snapshot.data ?? 0),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.list,
                        size: 14,
                        color: isDarkMode ? _darkTextSecondary : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      FutureBuilder<int>(
                        future: firestoreService.getChapterCount(book.id),
                        builder: (context, snapshot) => Text(
                          '${snapshot.data ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? _darkTextSecondary
                          : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: book.tags
                        .take(4)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode
                                    ? _darkTextSecondary
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              color: isDarkMode ? _darkTextSecondary : Colors.grey,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SEARCH TAB ====================
class _SearchTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final String userId;
  const _SearchTab({required this.firestoreService, required this.userId});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _query = '';
  List<String> _selectedTags = [];
  bool _safeSearch = true;

  final List<String> _popularTags = [
    'romance',
    'tragedy',
    'comedy',
    'bl',
    'fantasy',
    'mystery',
    'shortstory',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSafeSearch();
  }

  Future<void> _loadSafeSearch() async {
    final safe = await widget.firestoreService.getSafeSearch(widget.userId);
    setState(() => _safeSearch = safe);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: Column(
        children: [
          // Search header
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stories, writers...',
                hintStyle: TextStyle(
                  color: isDarkMode ? _darkTextSecondary : Colors.grey,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? _darkTextSecondary : Colors.grey,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? _darkCard : Colors.grey.shade200,
              ),
              style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // Filter tags
          if (_query.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'REFINE BY:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? _darkTextSecondary : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._popularTags
                      .take(3)
                      .map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag.toUpperCase()),
                            selected: _selectedTags.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                            selectedColor: _accentColor,
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: _selectedTags.contains(tag)
                                  ? Colors.white
                                  : (isDarkMode ? _darkText : Colors.black),
                            ),
                            backgroundColor: isDarkMode
                                ? _darkCard
                                : Colors.grey.shade200,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: _accentColor,
            unselectedLabelColor: isDarkMode ? _darkTextSecondary : Colors.grey,
            indicatorColor: _accentColor,
            tabs: const [
              Tab(text: 'STORIES'),
              Tab(text: 'PROFILES'),
              Tab(text: 'TAGS'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoriesTab(isDarkMode),
                _buildProfilesTab(isDarkMode),
                _buildTagsTab(isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesTab(bool isDarkMode) {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          'Search for stories by title or writer',
          style: TextStyle(
            color: isDarkMode ? _darkTextSecondary : Colors.grey,
          ),
        ),
      );
    }

    return FutureBuilder<List<BookModel>>(
      future: widget.firestoreService.searchBooks(
        _query,
        safeSearch: _safeSearch,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _accentColor),
          );
        }

        var books = snapshot.data ?? [];
        if (_selectedTags.isNotEmpty) {
          books = books
              .where(
                (b) =>
                    b.tags.any((t) => _selectedTags.contains(t.toLowerCase())),
              )
              .toList();
        }

        if (books.isEmpty) {
          return const Center(child: Text('No stories found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) => _BookListItem(
            book: books[index],
            firestoreService: widget.firestoreService,
          ),
        );
      },
    );
  }

  Widget _buildProfilesTab(bool isDarkMode) {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          'Search for writers by nickname',
          style: TextStyle(
            color: isDarkMode ? _darkTextSecondary : Colors.grey,
          ),
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: widget.firestoreService.searchWriters(_query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _accentColor),
          );
        }

        final writers = snapshot.data ?? [];
        if (writers.isEmpty) {
          return const Center(child: Text('No writers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: writers.length,
          itemBuilder: (context, index) {
            final writer = writers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _accentColor.withOpacity(0.2),
                child: Text(
                  writer.displayName[0].toUpperCase(),
                  style: const TextStyle(color: _accentColor),
                ),
              ),
              title: Text(
                writer.displayName,
                style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
              ),
              subtitle: Text(
                writer.email,
                style: TextStyle(
                  color: isDarkMode ? _darkTextSecondary : Colors.grey,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _WriterProfileScreen(
                    writer: writer,
                    firestoreService: widget.firestoreService,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTagsTab(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _popularTags
            .map(
              (tag) => ActionChip(
                label: Text('#$tag'),
                onPressed: () {
                  _searchController.text = tag;
                  setState(() {
                    _query = tag;
                    _tabController.animateTo(0);
                  });
                },
                backgroundColor: isDarkMode ? _darkCard : Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isDarkMode ? _darkText : Colors.black,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ==================== LIBRARY TAB ====================
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

  void _refreshLibrary() {
    setState(() {
      libraryBooks = widget.firestoreService.getReaderLibrary(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Library',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? _darkText : Colors.black,
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<BookModel>>(
              future: libraryBooks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 100,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your library is empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? _darkText : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add books to your library to read them anytime',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? _darkTextSecondary
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              final state = context
                                  .findAncestorStateOfType<_ReaderHomeState>();
                              state?.setState(() => state._currentIndex = 0);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text('Browse Stories'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshLibrary(),
                  color: _accentColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.55,
                        ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _LibraryBookCard(
                        book: book,
                        firestoreService: widget.firestoreService,
                        userId: widget.userId,
                        onRemoved: _refreshLibrary,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBookCard extends StatelessWidget {
  final BookModel book;
  final FirestoreService firestoreService;
  final String userId;
  final VoidCallback onRemoved;

  const _LibraryBookCard({
    required this.book,
    required this.firestoreService,
    required this.userId,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _BookDetailScreen(book: book, firestoreService: firestoreService),
        ),
      ),
      onLongPress: () => _showRemoveDialog(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildBookCover(
                book.coverImageUrl,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDarkMode ? _darkText : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? _darkCard : Colors.white,
        title: Text(
          'Remove from Library',
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        content: Text(
          'Remove "${book.title}" from your library?',
          style: TextStyle(
            color: isDarkMode ? _darkTextSecondary : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? _darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await firestoreService.removeBookFromLibrary(userId, book.id);
              Navigator.pop(ctx);
              onRemoved();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ==================== NOTIFICATIONS TAB ====================
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Updates',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? _darkText : Colors.black,
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<NotificationModel>>(
              future: notifications,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final notificationList = snapshot.data ?? [];

                if (notificationList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No updates yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notificationList.length,
                  itemBuilder: (context, index) {
                    final notif = notificationList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _accentColor.withOpacity(0.2),
                        child: const Icon(
                          Icons.notifications,
                          color: _accentColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.read
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: isDarkMode ? _darkText : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        notif.message,
                        style: TextStyle(
                          color: isDarkMode
                              ? _darkTextSecondary
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                      ),
                      trailing: notif.read
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () async {
                        if (!notif.read) {
                          await widget.firestoreService.markNotificationAsRead(
                            notif.id,
                          );
                          setState(
                            () => notifications = widget.firestoreService
                                .getUserNotifications(widget.userId),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PROFILE TAB ====================
class _ProfileTab extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;
  final String userId;

  const _ProfileTab({
    required this.authService,
    required this.firestoreService,
    required this.userId,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late final user = widget.authService.getCurrentUser();
  String _nickname = '';
  bool _safeSearch = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    themeService.addListener(_onThemeChanged);
  }

  void _loadUserData() async {
    final nickname = await widget.authService.getUserNickname(widget.userId);
    final safeSearch = await widget.firestoreService.getSafeSearch(
      widget.userId,
    );
    setState(() {
      _nickname = nickname;
      _safeSearch = safeSearch;
    });
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? _darkText : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: isDarkMode ? _darkText : Colors.black,
                    ),
                    onPressed: () => themeService.setDarkMode(!isDarkMode),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? _darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _accentColor.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nickname.isNotEmpty
                                ? _nickname
                                : (user?.displayName ?? 'Reader'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? _darkText : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? _darkTextSecondary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: isDarkMode ? _darkTextSecondary : Colors.grey,
                      ),
                      onPressed: () => _showEditNicknameDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? _darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.lock_outline,
                        color: isDarkMode
                            ? _darkTextSecondary
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        'Change Password',
                        style: TextStyle(
                          color: isDarkMode ? _darkText : Colors.black,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDarkMode
                            ? _darkTextSecondary
                            : Colors.grey.shade400,
                      ),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    Divider(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      height: 1,
                    ),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.shield_outlined,
                        color: isDarkMode
                            ? _darkTextSecondary
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        'Safe Search',
                        style: TextStyle(
                          color: isDarkMode ? _darkText : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Hide mature content',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                      ),
                      value: _safeSearch,
                      activeColor: _accentColor,
                      onChanged: (value) async {
                        await widget.firestoreService.updateSafeSearch(
                          widget.userId,
                          value,
                        );
                        setState(() => _safeSearch = value);
                      },
                    ),
                    Divider(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      height: 1,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDarkMode
                            ? _darkTextSecondary
                            : Colors.grey.shade400,
                      ),
                      onTap: () => _logout(context),
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

  void _showEditNicknameDialog(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    final controller = TextEditingController(text: _nickname);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? _darkCard : Colors.white,
        title: Text(
          'Edit Nickname',
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nickname',
            labelStyle: TextStyle(
              color: isDarkMode ? _darkTextSecondary : Colors.grey,
            ),
          ),
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? _darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.authService.updateNickname(controller.text);
              Navigator.pop(ctx);
              _loadUserData();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Nickname updated')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? _darkCard : Colors.white,
        title: Text(
          'Change Password',
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(
                  color: isDarkMode ? _darkTextSecondary : Colors.grey,
                ),
              ),
              obscureText: true,
              style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(
                  color: isDarkMode ? _darkTextSecondary : Colors.grey,
                ),
              ),
              obscureText: true,
              style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? _darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              try {
                await widget.authService.changePassword(
                  newPasswordController.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? _darkCard : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: isDarkMode ? _darkTextSecondary : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? _darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ==================== BOOK DETAIL SCREEN ====================
class _BookDetailScreen extends StatefulWidget {
  final BookModel book;
  final FirestoreService firestoreService;

  const _BookDetailScreen({required this.book, required this.firestoreService});

  @override
  State<_BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<_BookDetailScreen> {
  late Future<List<ChapterModel>> chapters;
  late Future<int> totalVotes;
  late Future<int> chapterCount;
  late Future<int> commentCount;
  bool _inLibrary = false;
  bool _askedToAddLibrary = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    chapters = widget.firestoreService.getChaptersByBook(widget.book.id);
    totalVotes = widget.firestoreService.getTotalVotesForBook(widget.book.id);
    chapterCount = widget.firestoreService.getChapterCount(widget.book.id);
    commentCount = widget.firestoreService.getCommentCount(widget.book.id);
    _checkLibrary();
    // Increment read count
    widget.firestoreService.incrementReadCount(widget.book.id);
  }

  Future<void> _checkLibrary() async {
    if (currentUser != null) {
      final inLib = await widget.firestoreService.isBookInLibrary(
        currentUser!.uid,
        widget.book.id,
      );
      setState(() => _inLibrary = inLib);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg)
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.grey.shade100,
            ),
      child: WillPopScope(
        onWillPop: () async {
          if (!_inLibrary && !_askedToAddLibrary && currentUser != null) {
            _askedToAddLibrary = true;
            final shouldAdd = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: isDarkMode ? _darkCard : Colors.white,
                title: Text(
                  'Add to Library?',
                  style: TextStyle(
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                ),
                content: Text(
                  'Would you like to add "${widget.book.title}" to your library?',
                  style: TextStyle(
                    color: isDarkMode
                        ? _darkTextSecondary
                        : Colors.grey.shade700,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: isDarkMode ? _darkTextSecondary : Colors.grey,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                    ),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
            if (shouldAdd == true) {
              try {
                await widget.firestoreService.addBookToLibrary(
                  currentUser!.uid,
                  widget.book.id,
                );
                setState(() => _inLibrary = true);
              } catch (e) {
                // Silently fail - permission error
              }
            }
          }
          return true;
        },
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: isDarkMode ? _darkBg : Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBookCover(
                        widget.book.coverImageUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDarkMode ? _darkBg : Colors.white).withOpacity(
                                0.9,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.book.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? _darkText : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.writerNickname.isNotEmpty
                            ? widget.book.writerNickname
                            : 'Unknown Writer',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatItem(
                            icon: Icons.visibility,
                            value: _formatNumber(widget.book.readCount),
                            label: 'Reads',
                          ),
                          const SizedBox(width: 24),
                          FutureBuilder<int>(
                            future: totalVotes,
                            builder: (_, s) => _StatItem(
                              icon: Icons.star,
                              value: _formatNumber(s.data ?? 0),
                              label: 'Votes',
                            ),
                          ),
                          const SizedBox(width: 24),
                          FutureBuilder<int>(
                            future: chapterCount,
                            builder: (_, s) => _StatItem(
                              icon: Icons.list,
                              value: '${s.data ?? 0}',
                              label: 'Parts',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Read and Add to Library buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _startReading(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text('Read'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              onPressed: _toggleLibrary,
                              icon: Icon(
                                _inLibrary ? Icons.check : Icons.add,
                                color: _accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Tags
                      if (widget.book.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.book.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? _darkTextSecondary
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                      const SizedBox(height: 20),

                      // Description
                      if (widget.book.description.isNotEmpty)
                        Text(
                          widget.book.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Chapter list header
                      Row(
                        children: [
                          Text(
                            'Table of Contents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? _darkText : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          FutureBuilder<int>(
                            future: chapterCount,
                            builder: (_, s) => Text(
                              '${s.data ?? 0} Parts',
                              style: TextStyle(
                                color: isDarkMode
                                    ? _darkTextSecondary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Chapters
              FutureBuilder<List<ChapterModel>>(
                future: chapters,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(color: _accentColor),
                      ),
                    );
                  }

                  final chapterList = snapshot.data ?? [];
                  if (chapterList.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No chapters available yet',
                            style: TextStyle(
                              color: isDarkMode
                                  ? _darkTextSecondary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final chapter = chapterList[index];
                      return ListTile(
                        leading: Text(
                          '(${chapter.chapterNumber})',
                          style: TextStyle(
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          chapter.title,
                          style: TextStyle(
                            color: isDarkMode ? _darkText : Colors.black,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                        onTap: () =>
                            _openChapter(context, chapter, chapterList),
                      );
                    }, childCount: chapterList.length),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLibrary() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to library')),
      );
      return;
    }

    try {
      if (_inLibrary) {
        await widget.firestoreService.removeBookFromLibrary(
          currentUser!.uid,
          widget.book.id,
        );
        setState(() => _inLibrary = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from library')));
      } else {
        await widget.firestoreService.addBookToLibrary(
          currentUser!.uid,
          widget.book.id,
        );
        setState(() => _inLibrary = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to library')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _startReading(BuildContext context) async {
    final chapterList = await chapters;
    if (chapterList.isNotEmpty) {
      // Check for saved position
      if (currentUser != null && _inLibrary) {
        final position = await widget.firestoreService.getReadingPosition(
          currentUser!.uid,
          widget.book.id,
        );
        if (position != null && position['lastChapterId'] != null) {
          final lastChapter = chapterList.firstWhere(
            (c) => c.id == position['lastChapterId'],
            orElse: () => chapterList.first,
          );
          _openChapter(
            context,
            lastChapter,
            chapterList,
            scrollPosition: position['scrollPosition'],
          );
          return;
        }
      }
      _openChapter(context, chapterList.first, chapterList);
    }
  }

  void _openChapter(
    BuildContext context,
    ChapterModel chapter,
    List<ChapterModel> allChapters, {
    double scrollPosition = 0.0,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterReadScreen(
          chapter: chapter,
          allChapters: allChapters,
          firestoreService: widget.firestoreService,
          book: widget.book,
          initialScrollPosition: scrollPosition,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDarkMode ? _darkTextSecondary : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? _darkText : Colors.black,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? _darkTextSecondary : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ==================== CHAPTER READ SCREEN ====================
class _ChapterReadScreen extends StatefulWidget {
  final ChapterModel chapter;
  final List<ChapterModel> allChapters;
  final FirestoreService firestoreService;
  final BookModel book;
  final double initialScrollPosition;

  const _ChapterReadScreen({
    required this.chapter,
    required this.allChapters,
    required this.firestoreService,
    required this.book,
    this.initialScrollPosition = 0.0,
  });

  @override
  State<_ChapterReadScreen> createState() => _ChapterReadScreenState();
}

class _ChapterReadScreenState extends State<_ChapterReadScreen> {
  late ChapterModel _currentChapter;
  late ScrollController _scrollController;
  late Future<int> voteCount;
  late Future<bool> hasVoted;
  late Future<List<CommentModel>> comments;
  final currentUser = FirebaseAuth.instance.currentUser;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollPosition,
    );
    _refreshData();
  }

  @override
  void dispose() {
    _saveReadingPosition();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveReadingPosition() async {
    if (currentUser != null) {
      final inLibrary = await widget.firestoreService.isBookInLibrary(
        currentUser!.uid,
        widget.book.id,
      );
      if (inLibrary) {
        await widget.firestoreService.saveReadingPosition(
          currentUser!.uid,
          widget.book.id,
          _currentChapter.id,
          _scrollController.offset,
        );
      }
    }
  }

  void _refreshData() {
    voteCount = widget.firestoreService.getVoteCount(_currentChapter.id);
    if (currentUser != null) {
      hasVoted = widget.firestoreService.hasUserVoted(
        _currentChapter.id,
        currentUser!.uid,
      );
    } else {
      hasVoted = Future.value(false);
    }
    comments = widget.firestoreService.getCommentsByChapter(_currentChapter.id);
  }

  // Parse text and build formatted TextSpans
  List<TextSpan> _buildFormattedText(String content, bool isDarkMode) {
    // First try to parse as Quill Delta JSON
    String text;
    try {
      final deltaJson = jsonDecode(content) as List;
      text = deltaJson
          .map(
            (op) => op is Map && op.containsKey('insert')
                ? op['insert'].toString()
                : '',
          )
          .join();
    } catch (e) {
      text = content;
    }

    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(r'\*\*(.+?)\*\*|_(.+?)_|<u>(.+?)</u>');
    final textColor = isDarkMode ? _darkText : Colors.black;

    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add plain text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Determine formatting type and add styled span
      if (match.group(1) != null) {
        // Bold **text**
        spans.add(
          TextSpan(
            text: match.group(1),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        );
      } else if (match.group(2) != null) {
        // Italic _text_
        spans.add(
          TextSpan(
            text: match.group(2),
            style: TextStyle(fontStyle: FontStyle.italic, color: textColor),
          ),
        );
      } else if (match.group(3) != null) {
        // Underline <u>text</u>
        spans.add(
          TextSpan(
            text: match.group(3),
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: textColor,
            ),
          ),
        );
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
    final isDarkMode = themeService.isDarkMode;
    final currentIndex = widget.allChapters.indexWhere(
      (c) => c.id == _currentChapter.id,
    );
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < widget.allChapters.length - 1;

    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg)
          : ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.white),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentChapter.title,
            style: TextStyle(
              color: isDarkMode ? _darkText : Colors.black,
              fontSize: 16,
            ),
          ),
          iconTheme: IconThemeData(
            color: isDarkMode ? _darkText : Colors.black,
          ),
          backgroundColor: isDarkMode ? _darkBg : Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () => _showFontSizeDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _showChapterList(context),
            ),
          ],
        ),
        body: GestureDetector(
          onLongPressStart: (details) =>
              _showInlineCommentDialog(context, details.globalPosition),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: SelectableText.rich(
              TextSpan(
                children: _buildFormattedText(
                  _currentChapter.content,
                  isDarkMode,
                ),
                style: TextStyle(
                  fontSize: _fontSize,
                  color: isDarkMode ? _darkText : Colors.black,
                  height: 1.8,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? _darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Vote
                FutureBuilder<bool>(
                  future: hasVoted,
                  builder: (context, snapshot) {
                    final voted = snapshot.data ?? false;
                    return _BottomBarItem(
                      icon: voted ? Icons.star : Icons.star_border,
                      label: 'Vote',
                      color: voted ? Colors.amber : null,
                      onTap: () async {
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to vote'),
                            ),
                          );
                          return;
                        }
                        await widget.firestoreService.addVote(
                          _currentChapter.id,
                          currentUser!.uid,
                        );
                        setState(() => _refreshData());
                      },
                    );
                  },
                ),
                // Comments
                FutureBuilder<List<CommentModel>>(
                  future: comments,
                  builder: (context, snapshot) {
                    return _BottomBarItem(
                      icon: Icons.comment_outlined,
                      label: '${snapshot.data?.length ?? 0}',
                      onTap: () => _showCommentsSheet(context),
                    );
                  },
                ),
                // Share
                _BottomBarItem(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
                // Previous/Next
                if (hasPrevious)
                  _BottomBarItem(
                    icon: Icons.arrow_back,
                    label: 'Prev',
                    onTap: () {
                      setState(() {
                        _currentChapter = widget.allChapters[currentIndex - 1];
                        _scrollController.jumpTo(0);
                        _refreshData();
                      });
                    },
                  ),
                if (hasNext)
                  _BottomBarItem(
                    icon: Icons.arrow_forward,
                    label: 'Next',
                    onTap: () {
                      setState(() {
                        _currentChapter = widget.allChapters[currentIndex + 1];
                        _scrollController.jumpTo(0);
                        _refreshData();
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChapterList(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? _darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chapters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? _darkText : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.allChapters.length,
              itemBuilder: (context, index) {
                final chapter = widget.allChapters[index];
                final isCurrentChapter = chapter.id == _currentChapter.id;
                return ListTile(
                  leading: Text(
                    '(${chapter.chapterNumber})',
                    style: TextStyle(
                      color: isCurrentChapter
                          ? _accentColor
                          : (isDarkMode ? _darkTextSecondary : Colors.grey),
                    ),
                  ),
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      color: isCurrentChapter
                          ? _accentColor
                          : (isDarkMode ? _darkText : Colors.black),
                      fontWeight: isCurrentChapter
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrentChapter
                      ? const Icon(Icons.play_arrow, color: _accentColor)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentChapter = chapter;
                      _scrollController.jumpTo(0);
                      _refreshData();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? _darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Font Size',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? _darkText : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (_fontSize > 12) {
                      setState(() => _fontSize -= 2);
                    }
                  },
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: isDarkMode ? _darkText : Colors.black,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '${_fontSize.toInt()}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () {
                    if (_fontSize < 32) {
                      setState(() => _fontSize += 2);
                    }
                  },
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: isDarkMode ? _darkText : Colors.black,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sample Text',
              style: TextStyle(
                fontSize: _fontSize,
                color: isDarkMode ? _darkText : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showInlineCommentDialog(BuildContext context, Offset position) {
    final isDarkMode = themeService.isDarkMode;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? _darkCard : Colors.white,
        title: Text(
          'Add Comment',
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: 'Write your comment...',
            hintStyle: TextStyle(
              color: isDarkMode ? _darkTextSecondary : Colors.grey,
            ),
          ),
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? _darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.isNotEmpty) {
                final nickname = await AuthService().getUserNickname(
                  currentUser!.uid,
                );
                await widget.firestoreService.addComment(
                  widget.book.id,
                  currentUser!.uid,
                  commentController.text,
                  chapterId: _currentChapter.id,
                  userNickname: nickname,
                );
                Navigator.pop(ctx);
                setState(() => _refreshData());
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Comment added')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? _darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<CommentModel>>(
                future: comments,
                builder: (context, snapshot) => Text(
                  '${snapshot.data?.length ?? 0} Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<CommentModel>>(
                future: comments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    );
                  }

                  final commentList = snapshot.data ?? [];
                  if (commentList.isEmpty) {
                    return Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: commentList.length,
                    itemBuilder: (context, index) {
                      final comment = commentList[index];
                      return _CommentItem(
                        comment: comment,
                        firestoreService: widget.firestoreService,
                        bookId: widget.book.id,
                        chapterId: _currentChapter.id,
                        onReply: () => setState(() => _refreshData()),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _accentColor.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Post a comment...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? _darkBg : Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? _darkText : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (commentController.text.isNotEmpty) {
                        final nickname = await AuthService().getUserNickname(
                          currentUser!.uid,
                        );
                        await widget.firestoreService.addComment(
                          widget.book.id,
                          currentUser!.uid,
                          commentController.text,
                          chapterId: _currentChapter.id,
                          userNickname: nickname,
                        );
                        commentController.clear();
                        setState(() => _refreshData());
                      }
                    },
                    icon: const Icon(Icons.send, color: _accentColor),
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

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? (isDarkMode ? _darkTextSecondary : Colors.grey),
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color ?? (isDarkMode ? _darkTextSecondary : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatefulWidget {
  final CommentModel comment;
  final FirestoreService firestoreService;
  final String bookId;
  final String chapterId;
  final VoidCallback onReply;

  const _CommentItem({
    required this.comment,
    required this.firestoreService,
    required this.bookId,
    required this.chapterId,
    required this.onReply,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _showReplies = false;
  late Future<List<CommentModel>> replies;

  @override
  void initState() {
    super.initState();
    replies = widget.firestoreService.getCommentReplies(widget.comment.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    final dateFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quoted text if inline comment
          if (widget.comment.selectedText != null &&
              widget.comment.selectedText!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? _darkBg : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: _accentColor, width: 3)),
              ),
              child: Text(
                widget.comment.selectedText!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? _darkTextSecondary : Colors.grey.shade700,
                ),
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _accentColor.withOpacity(0.2),
                child: Text(
                  widget.comment.userNickname.isNotEmpty
                      ? widget.comment.userNickname[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: _accentColor, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.comment.userNickname.isNotEmpty
                              ? widget.comment.userNickname
                              : 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDarkMode ? _darkText : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.reply, size: 18),
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                          onPressed: () => _showReplyDialog(context),
                        ),
                      ],
                    ),
                    Text(
                      widget.comment.message,
                      style: TextStyle(
                        color: isDarkMode ? _darkText : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(widget.comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? _darkTextSecondary : Colors.grey,
                      ),
                    ),

                    // Replies
                    FutureBuilder<List<CommentModel>>(
                      future: replies,
                      builder: (context, snapshot) {
                        final replyList = snapshot.data ?? [];
                        if (replyList.isEmpty) return const SizedBox();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showReplies = !_showReplies),
                              child: Text(
                                _showReplies
                                    ? 'Hide replies'
                                    : 'View ${replyList.length} replies',
                                style: const TextStyle(
                                  color: _accentColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (_showReplies)
                              ...replyList.map(
                                (reply) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    top: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: _accentColor
                                            .withOpacity(0.2),
                                        child: Text(
                                          reply.userNickname.isNotEmpty
                                              ? reply.userNickname[0]
                                                    .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: _accentColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reply.userNickname.isNotEmpty
                                                  ? reply.userNickname
                                                  : 'Anonymous',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? _darkText
                                                    : Colors.black,
                                              ),
                                            ),
                                            Text(
                                              reply.message,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? _darkText
                                                    : Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              dateFormat.format(
                                                reply.createdAt,
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDarkMode
                                                    ? _darkTextSecondary
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;
    final replyController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? _darkCard : Colors.white,
        title: Text(
          'Reply to ${widget.comment.userNickname}',
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
        ),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(
            hintText: 'Write your reply...',
            hintStyle: TextStyle(
              color: isDarkMode ? _darkTextSecondary : Colors.grey,
            ),
          ),
          style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? _darkTextSecondary : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty && currentUser != null) {
                final nickname = await AuthService().getUserNickname(
                  currentUser.uid,
                );
                await widget.firestoreService.addComment(
                  widget.bookId,
                  currentUser.uid,
                  replyController.text,
                  chapterId: widget.chapterId,
                  userNickname: nickname,
                  parentCommentId: widget.comment.id,
                );
                Navigator.pop(ctx);
                widget.onReply();
                setState(
                  () => replies = widget.firestoreService.getCommentReplies(
                    widget.comment.id,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }
}

// ==================== WRITER PROFILE SCREEN ====================
class _WriterProfileScreen extends StatelessWidget {
  final UserModel writer;
  final FirestoreService firestoreService;

  const _WriterProfileScreen({
    required this.writer,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: _darkBg)
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.grey.shade100,
            ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            writer.displayName,
            style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
          ),
          backgroundColor: isDarkMode ? _darkBg : Colors.white,
          iconTheme: IconThemeData(
            color: isDarkMode ? _darkText : Colors.black,
          ),
        ),
        body: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _accentColor.withOpacity(0.2),
                    child: Text(
                      writer.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    writer.displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? _darkText : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Writer',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? _darkTextSecondary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Published books section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Published Stories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? _darkText : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Books list
            Expanded(
              child: FutureBuilder<List<BookModel>>(
                future: firestoreService.getPublishedBooksByWriter(writer.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    );
                  }

                  final books = snapshot.data ?? [];
                  if (books.isEmpty) {
                    return Center(
                      child: Text(
                        'No published stories yet',
                        style: TextStyle(
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _BookListItem(
                        book: book,
                        firestoreService: firestoreService,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
