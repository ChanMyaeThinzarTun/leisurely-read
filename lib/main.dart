import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/writer_home.dart';
import 'screens/reader_home.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
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
    return MaterialApp(
      title: 'Leisurely Read',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/writer': (context) => const WriterHome(),
        '/reader': (context) => const ReaderHome(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        return const _RoleBasedHome();
      },
    );
  }
}

class _RoleBasedHome extends StatefulWidget {
  const _RoleBasedHome();

  @override
  State<_RoleBasedHome> createState() => _RoleBasedHomeState();
}

class _RoleBasedHomeState extends State<_RoleBasedHome> {
  bool _isAccountDeleted = false;

  void _handleAccountDeleted() {
    if (!_isAccountDeleted) {
      setState(() {
        _isAccountDeleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If account was deleted, keep showing the deleted screen
    if (_isAccountDeleted) {
      return _buildAccountDeletedScreen();
    }

    // Use StreamBuilder to listen for real-time changes (including bans)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Debug logging
        print('StreamBuilder state: ${snapshot.connectionState}');
        print('Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          print('Document exists: ${snapshot.data!.exists}');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Error loading user data: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Error Loading User Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Make sure your admin user is set up in Firestore.\nSee SETUP_FIX.md for instructions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Logout & Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user document was deleted
        final docExists = snapshot.hasData && snapshot.data!.exists;
        if (!docExists) {
          // Schedule the state update after the build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleAccountDeleted();
          });
          return _buildAccountDeletedScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'];
        final isApproved = userData['isApproved'] ?? false;

        // Check if user is banned
        if (userData['bannedUntil'] != null) {
          final raw = userData['bannedUntil'];
          DateTime? bannedUntil;
          if (raw is DateTime) {
            bannedUntil = raw;
          } else if (raw is Timestamp) {
            bannedUntil = raw.toDate();
          }
          if (bannedUntil != null && bannedUntil.isAfter(DateTime.now())) {
            return _BannedScreen(bannedUntil: bannedUntil);
          }
        }

        if (role == 'admin') {
          return const AdminDashboard();
        } else if (role == 'writer' && !isApproved) {
          return const _PendingApprovalScreen();
        } else if (role == 'writer') {
          return const WriterHome();
        } else {
          return const ReaderHome();
        }
      },
    );
  }

  Widget _buildAccountDeletedScreen() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
        title: const Text('Account Status'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Account Deleted',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your account has been removed\nby an administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approval')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending, size: 80, color: Color(0xFFFFB74D)),
            const SizedBox(height: 24),
            const Text(
              'Your writer account is pending admin approval',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannedScreen extends StatefulWidget {
  final DateTime bannedUntil;

  const _BannedScreen({required this.bannedUntil});

  @override
  State<_BannedScreen> createState() => _BannedScreenState();
}

class _BannedScreenState extends State<_BannedScreen> {
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    // Check every minute if ban has expired
    _startExpirationTimer();
  }

  void _updateTimeRemaining() {
    _timeRemaining = widget.bannedUntil.difference(DateTime.now());
  }

  void _startExpirationTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (!mounted) return;
      _updateTimeRemaining();
      if (_timeRemaining.isNegative) {
        // Ban expired - trigger rebuild by forcing auth state refresh
        setState(() {});
      } else {
        _startExpirationTimer();
      }
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $amPm';
  }

  String _getTimeRemaining() {
    if (_timeRemaining.isNegative) return 'Ban expired';

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;

    if (days > 0) {
      return '$days day${days != 1 ? 's' : ''}, $hours hr${hours != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hr${hours != 1 ? 's' : ''}, $minutes min';
    } else {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if ban has expired
    if (_timeRemaining.isNegative) {
      // Return empty scaffold - StreamBuilder will rebuild with new data
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDarkMode = themeService.isDarkMode;

    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF121212),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.grey.shade100,
            ),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ban icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.block, size: 64, color: Colors.red),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Account Suspended',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Violation message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your account has been suspended for violation of community rules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDarkMode
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Days remaining
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getTimeRemaining(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Access restore date
                  Text(
                    'Access will be restored on:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(widget.bannedUntil),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
