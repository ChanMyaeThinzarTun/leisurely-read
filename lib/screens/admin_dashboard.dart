import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Writers'),
            Tab(text: 'Books'),
            Tab(text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(firestoreService: firestoreService),
          _WritersTab(firestoreService: firestoreService),
          _BooksTab(firestoreService: firestoreService),
          _SettingsTab(
            authService: authService,
            onPasswordChanged: changePassword,
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

class _UsersTab extends StatefulWidget {
  final FirestoreService firestoreService;
  const _UsersTab({required this.firestoreService});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late Future<List<UserModel>> users;

  @override
  void initState() {
    super.initState();
    users = widget.firestoreService.getAllUsers();
  }

  void refreshUsers() {
    setState(() {
      users = widget.firestoreService.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        final userList = snapshot.data!;
        return ListView.builder(
          itemCount: userList.length,
          itemBuilder: (context, index) {
            final user = userList[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(user.email),
                subtitle: Text('Role: ${user.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.isBanned)
                      Tooltip(
                        message: 'Unban',
                        child: IconButton(
                          icon: const Icon(
                            Icons.lock_open,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            await widget.firestoreService.unbanUser(user.uid);
                            refreshUsers();
                          },
                        ),
                      )
                    else
                      Tooltip(
                        message: 'Ban',
                        child: IconButton(
                          icon: const Icon(
                            Icons.lock,
                            color: Color(0xFFFFB74D),
                          ),
                          onPressed: () => _showBanDialog(context, user),
                        ),
                      ),
                    Tooltip(
                      message: 'Delete',
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete User'),
                              content: Text('Delete ${user.email}?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await widget.firestoreService.deleteUser(user.uid);
                            refreshUsers();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBanDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ban ${user.email} until:'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: 1,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 day')),
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 365, child: Text('1 year')),
              ],
              onChanged: (value) {
                if (value != null) {
                  final bannedUntil = DateTime.now().add(Duration(days: value));
                  widget.firestoreService.banUser(user.uid, bannedUntil).then((
                    _,
                  ) {
                    Navigator.pop(context);
                    setState(() {
                      users = widget.firestoreService.getAllUsers();
                    });
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WritersTab extends StatefulWidget {
  final FirestoreService firestoreService;
  const _WritersTab({required this.firestoreService});

  @override
  State<_WritersTab> createState() => _WritersTabState();
}

class _WritersTabState extends State<_WritersTab> {
  late Future<List<UserModel>> writers;

  @override
  void initState() {
    super.initState();
    writers = widget.firestoreService.getUnapprovedWriters();
  }

  void refreshWriters() {
    setState(() {
      writers = widget.firestoreService.getUnapprovedWriters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: writers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending writer approvals'));
        }

        final writerList = snapshot.data!;
        return ListView.builder(
          itemCount: writerList.length,
          itemBuilder: (context, index) {
            final writer = writerList[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(writer.email),
                subtitle: const Text('Pending approval'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await widget.firestoreService.approveWriter(writer.uid);
                        refreshWriters();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${writer.email} approved')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await widget.firestoreService.rejectWriter(writer.uid);
                        refreshWriters();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${writer.email} rejected')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BooksTab extends StatefulWidget {
  final FirestoreService firestoreService;
  const _BooksTab({required this.firestoreService});

  @override
  State<_BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<_BooksTab> {
  late Future<List<BookModel>> books;

  @override
  void initState() {
    super.initState();
    books = widget.firestoreService.getAllBooks();
  }

  void refreshBooks() {
    setState(() {
      books = widget.firestoreService.getAllBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookModel>>(
      future: books,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No books found'));
        }

        final bookList = snapshot.data!;
        return ListView.builder(
          itemCount: bookList.length,
          itemBuilder: (context, index) {
            final book = bookList[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Image.network(
                  book.coverImageUrl,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book),
                  ),
                ),
                title: Text(book.title),
                subtitle: Text('By: ${book.writerId}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Book'),
                        content: Text('Delete "${book.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await widget.firestoreService.deleteBook(book.id);
                      refreshBooks();
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onPasswordChanged;

  const _SettingsTab({
    required this.authService,
    required this.onPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: onPasswordChanged,
          ),
        ),
        const SizedBox(height: 24),
        Text('Admin Info', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${authService.getCurrentUser()?.email ?? 'N/A'}'),
                const SizedBox(height: 8),
                const Text('Role: Admin'),
              ],
            ),
          ),
        ),
      ],
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
