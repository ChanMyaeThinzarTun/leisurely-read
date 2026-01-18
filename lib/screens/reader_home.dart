import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';

// Theme colors
const _darkBg = Color(0xFF121212);
const _darkCard = Color(0xFF1E1E1E);
const _darkText = Colors.white;
const _darkTextSecondary = Color(0xFFAAAAAA);
const _accentColor = Color(0xFF00BFA5); // Teal

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
      _BrowseTab(firestoreService: firestoreService),
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
                    Icons.library_books_outlined,
                    Icons.library_books,
                    'Library',
                  ),
                  _buildNavItem(
                    2,
                    Icons.notifications_outlined,
                    Icons.notifications,
                    'Updates',
                  ),
                  _buildNavItem(
                    3,
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
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? _accentColor
                  : (isDarkMode ? _darkTextSecondary : Colors.grey),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(1),
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
  const _BrowseTab({required this.firestoreService});

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  late Future<List<BookModel>> books;
  String _selectedCategory = 'All';

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
    books = widget.firestoreService.getAllBooks();
  }

  void _refreshBooks() {
    setState(() {
      books = widget.firestoreService.getAllBooks();
    });
  }

  List<BookModel> _filterBooks(List<BookModel> allBooks) {
    return allBooks.where((book) {
      final matchesCategory =
          _selectedCategory == 'All' || book.category == _selectedCategory;
      return matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: Column(
        children: [
          // Header
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
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: isDarkMode ? _darkText : Colors.black,
                  ),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: _BookSearchDelegate(widget.firestoreService),
                    );
                  },
                ),
              ],
            ),
          ),

          // Category filter
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
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
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

          // Books grid
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
                final filteredBooks = _filterBooks(allBooks);

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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.55,
                        ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return _BookCard(
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

class _BookCard extends StatelessWidget {
  final BookModel book;
  final FirestoreService firestoreService;

  const _BookCard({required this.book, required this.firestoreService});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildBookCover(
                    book.coverImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (book.isMature)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '18+',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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
          // Header
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

          // Library content
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
                              // Navigate to browse
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

  void _refreshNotifications() {
    setState(() {
      notifications = widget.firestoreService.getUserNotifications(
        widget.userId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Notifications list
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
                        const SizedBox(height: 8),
                        Text(
                          'Updates from books in your library\nwill appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshNotifications(),
                  color: _accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notificationList.length,
                    itemBuilder: (context, index) {
                      final notif = notificationList[index];
                      return _NotificationCard(
                        notification: notif,
                        firestoreService: widget.firestoreService,
                        onRead: _refreshNotifications,
                        isDarkMode: isDarkMode,
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

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final FirestoreService firestoreService;
  final VoidCallback onRead;
  final bool isDarkMode;

  const _NotificationCard({
    required this.notification,
    required this.firestoreService,
    required this.onRead,
    required this.isDarkMode,
  });

  IconData _getNotificationIcon() {
    if (notification.title.toLowerCase().contains('chapter')) {
      return Icons.menu_book;
    } else if (notification.title.toLowerCase().contains('like') ||
        notification.title.toLowerCase().contains('vote')) {
      return Icons.thumb_up;
    } else if (notification.title.toLowerCase().contains('comment') ||
        notification.title.toLowerCase().contains('reply')) {
      return Icons.comment;
    }
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.read
            ? (isDarkMode ? _darkCard : Colors.white)
            : (isDarkMode
                  ? _accentColor.withOpacity(0.1)
                  : _accentColor.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(12),
        border: notification.read
            ? null
            : Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accentColor.withOpacity(0.2),
          child: Icon(_getNotificationIcon(), color: _accentColor, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            color: isDarkMode ? _darkText : Colors.black,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            notification.message,
            style: TextStyle(
              color: isDarkMode ? _darkTextSecondary : Colors.grey.shade600,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: notification.read
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
          if (!notification.read) {
            await firestoreService.markNotificationAsRead(notification.id);
            onRead();
          }
        },
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
  late Future<List<BookModel>> recentBooks;

  @override
  void initState() {
    super.initState();
    recentBooks = widget.firestoreService.getReaderLibrary(widget.userId);
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
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
                    onPressed: () {
                      themeService.setDarkMode(!isDarkMode);
                    },
                  ),
                ],
              ),
            ),

            // Profile info
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
                            user?.displayName ?? 'Reader',
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recently Read section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: _accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recently Read',
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

            FutureBuilder<List<BookModel>>(
              future: recentBooks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final books = snapshot.data ?? [];
                if (books.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No books read yet',
                      style: TextStyle(
                        color: isDarkMode
                            ? _darkTextSecondary
                            : Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: books.take(10).length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _BookDetailScreen(
                                book: book,
                                firestoreService: widget.firestoreService,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildBookCover(
                                  book.coverImageUrl,
                                  width: 100,
                                  height: 130,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDarkMode ? _darkText : Colors.black,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Settings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? _darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () => _showChangePasswordDialog(context),
                      isDarkMode: isDarkMode,
                    ),
                    Divider(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      height: 1,
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => _logout(context),
                      isDarkMode: isDarkMode,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : (isDarkMode ? _darkTextSecondary : Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Colors.red
              : (isDarkMode ? _darkText : Colors.black),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? _darkTextSecondary : Colors.grey.shade400,
      ),
      onTap: onTap,
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
  bool _inLibrary = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    chapters = widget.firestoreService.getChaptersByBook(widget.book.id);
    _checkLibrary();
  }

  Future<void> _checkLibrary() async {
    if (currentUser != null) {
      final library = await widget.firestoreService.getReaderLibrary(
        currentUser!.uid,
      );
      setState(() {
        _inLibrary = library.any((b) => b.id == widget.book.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeService.isDarkMode;

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
        body: CustomScrollView(
          slivers: [
            // App Bar with cover
            SliverAppBar(
              expandedHeight: 280,
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
            ),

            // Book info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? _darkText : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (widget.book.category.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.book.category,
                              style: const TextStyle(
                                color: _accentColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (widget.book.isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          if (widget.book.isMature) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '18+',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add to library button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startReading(context),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Reading'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _toggleLibrary,
                          icon: Icon(
                            _inLibrary ? Icons.bookmark : Icons.bookmark_border,
                            color: _accentColor,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _accentColor.withOpacity(0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Description
                    if (widget.book.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? _darkText : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? _darkTextSecondary
                              : Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tags
                    if (widget.book.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.book.tags.map((tag) {
                          return Container(
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
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? _darkTextSecondary
                                    : Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Chapter list
                    Text(
                      'Chapters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? _darkText : Colors.black,
                      ),
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
                      leading: CircleAvatar(
                        backgroundColor: _accentColor.withOpacity(0.2),
                        child: Text(
                          '${chapter.chapterNumber}',
                          style: const TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
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
                      onTap: () => _openChapter(context, chapter, chapterList),
                    );
                  }, childCount: chapterList.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLibrary() async {
    if (currentUser == null) return;

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
  }

  void _startReading(BuildContext context) async {
    final chapterList = await chapters;
    if (chapterList.isNotEmpty) {
      _openChapter(context, chapterList.first, chapterList);
    }
  }

  void _openChapter(
    BuildContext context,
    ChapterModel chapter,
    List<ChapterModel> allChapters,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterReadScreen(
          chapter: chapter,
          allChapters: allChapters,
          firestoreService: widget.firestoreService,
        ),
      ),
    );
  }
}

// ==================== CHAPTER READ SCREEN ====================
class _ChapterReadScreen extends StatefulWidget {
  final ChapterModel chapter;
  final List<ChapterModel> allChapters;
  final FirestoreService firestoreService;

  const _ChapterReadScreen({
    required this.chapter,
    required this.allChapters,
    required this.firestoreService,
  });

  @override
  State<_ChapterReadScreen> createState() => _ChapterReadScreenState();
}

class _ChapterReadScreenState extends State<_ChapterReadScreen> {
  late ChapterModel _currentChapter;
  late Future<int> voteCount;
  late Future<bool> hasVoted;
  late Future<List<CommentModel>> comments;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _refreshData();
  }

  void _refreshData() {
    voteCount = widget.firestoreService.getVoteCount(_currentChapter.id);
    hasVoted = widget.firestoreService.hasUserVoted(
      _currentChapter.id,
      currentUser!.uid,
    );
    comments = widget.firestoreService.getCommentsByChapter(_currentChapter.id);
  }

  Widget _buildFormattedContent(String content) {
    try {
      final deltaJson = jsonDecode(content) as List;
      final spans = <TextSpan>[];

      for (var op in deltaJson) {
        if (op is Map && op.containsKey('insert')) {
          final text = op['insert'].toString();
          final attributes = op['attributes'] as Map<String, dynamic>?;

          TextStyle style = TextStyle(
            fontSize: 16,
            color: themeService.isDarkMode ? _darkText : Colors.black,
            height: 1.8,
          );

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
      return Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: themeService.isDarkMode ? _darkText : Colors.black,
          height: 1.8,
        ),
      );
    }
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
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: _darkBg,
              appBarTheme: const AppBarTheme(
                backgroundColor: _darkBg,
                elevation: 0,
              ),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
              ),
            ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chapter ${_currentChapter.chapterNumber}',
            style: TextStyle(color: isDarkMode ? _darkText : Colors.black),
          ),
          iconTheme: IconThemeData(
            color: isDarkMode ? _darkText : Colors.black,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentChapter.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? _darkText : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              _buildFormattedContent(_currentChapter.content),
              const SizedBox(height: 32),

              // Vote section
              Row(
                children: [
                  FutureBuilder<bool>(
                    future: hasVoted,
                    builder: (context, snapshot) {
                      final voted = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          voted ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: voted
                              ? _accentColor
                              : (isDarkMode ? _darkTextSecondary : Colors.grey),
                        ),
                        onPressed: () async {
                          await widget.firestoreService.addVote(
                            _currentChapter.id,
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
                      return Text(
                        '${snapshot.data ?? 0} votes',
                        style: TextStyle(
                          color: isDarkMode ? _darkTextSecondary : Colors.grey,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.comment_outlined,
                      color: isDarkMode ? _darkTextSecondary : Colors.grey,
                    ),
                    onPressed: () => _showCommentsSheet(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Navigation buttons
              Row(
                children: [
                  if (hasPrevious)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentChapter =
                                widget.allChapters[currentIndex - 1];
                            _refreshData();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(color: _accentColor),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  if (hasNext)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentChapter =
                                widget.allChapters[currentIndex + 1];
                            _refreshData();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Next Chapter'),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ],
          ),
        ),
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
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? _darkText : Colors.black,
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? _darkBg : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userId,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDarkMode
                                    ? _darkTextSecondary
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.message,
                              style: TextStyle(
                                color: isDarkMode ? _darkText : Colors.black,
                              ),
                            ),
                          ],
                        ),
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
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
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
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (commentController.text.isNotEmpty) {
                        await widget.firestoreService.addComment(
                          _currentChapter.bookId,
                          currentUser!.uid,
                          commentController.text,
                          chapterId: _currentChapter.id,
                        );
                        commentController.clear();
                        setState(() => _refreshData());
                        Navigator.pop(ctx);
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

// ==================== SEARCH DELEGATE ====================
class _BookSearchDelegate extends SearchDelegate<BookModel?> {
  final FirestoreService firestoreService;

  _BookSearchDelegate(this.firestoreService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Search for books...'));
    }

    return FutureBuilder<List<BookModel>>(
      future: firestoreService.getAllBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _accentColor),
          );
        }

        final books = (snapshot.data ?? []).where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
              book.description.toLowerCase().contains(query.toLowerCase()) ||
              book.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              );
        }).toList();

        if (books.isEmpty) {
          return const Center(child: Text('No books found'));
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              leading: SizedBox(
                width: 50,
                height: 70,
                child: _buildBookCover(book.coverImageUrl, fit: BoxFit.cover),
              ),
              title: Text(book.title),
              subtitle: Text(book.category),
              onTap: () {
                close(context, book);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _BookDetailScreen(
                      book: book,
                      firestoreService: firestoreService,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
