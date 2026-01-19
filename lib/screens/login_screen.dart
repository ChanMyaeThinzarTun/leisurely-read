import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool loading = false;
  bool _obscurePassword = true;
  bool _showAccountDeleted = false;

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    // Pre-fill with email if already entered
    resetEmailController.text = emailController.text.trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an email')),
                );
                return;
              }
              try {
                await authService.sendPasswordResetEmail(email);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset link sent! Check your email.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                String errorMessage = 'Failed to send reset email';
                if (e.toString().contains('user-not-found')) {
                  errorMessage = 'No account found with this email';
                } else if (e.toString().contains('invalid-email')) {
                  errorMessage = 'Invalid email format';
                }
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage)));
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void login() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an email')));
      return;
    }

    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a password')));
      return;
    }

    setState(() => loading = true);
    try {
      final user = await authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (user != null) {
        // Check if user document exists in Firestore
        print('DEBUG: Login successful, checking user document...');
        final userData = await authService.getUserData(user.uid);
        print('DEBUG: userData = $userData');
        print('DEBUG: userData.isEmpty = ${userData.isEmpty}');
        print('DEBUG: userData[role] = ${userData['role']}');

        // If userData is empty or null, account was deleted
        if (userData.isEmpty || userData['role'] == null) {
          print(
            'DEBUG: Account detected as deleted, showing deleted screen...',
          );
          // Don't sign out yet - show deleted screen first
          // Sign out will happen when user clicks back button
          if (mounted) {
            setState(() {
              _showAccountDeleted = true;
              loading = false;
            });
          }
          return;
        }

        final role = userData['role'];
        final isApproved = userData['isApproved'] ?? false;

        print(
          'User logged in: ${user.email}, Role: $role, Approved: $isApproved',
        );

        // Don't navigate manually - let AuthWrapper handle it
        // This ensures ban checks in _RoleBasedHome are applied
        if (role == 'writer' && !isApproved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Writer account pending admin approval. Please wait.',
                ),
              ),
            );
          }
        }
        // Navigate to root to let AuthWrapper show the correct screen
        // This handles the case where user was already logged in
        if (mounted) {
          setState(() => loading = false);
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        print('Login Error: $e');
        String errorMessage = e.toString();

        // Parse Firebase errors into friendly messages
        if (errorMessage.contains('user-not-found') ||
            errorMessage.contains('INVALID_LOGIN_CREDENTIALS')) {
          errorMessage =
              'No account found with this email. Please sign up first.';
        } else if (errorMessage.contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (errorMessage.contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (errorMessage.contains('invalid-credential')) {
          errorMessage =
              'Invalid email or password. Please check and try again.';
        } else if (errorMessage.contains('too-many-requests')) {
          errorMessage =
              'Too many failed attempts. Please wait a few minutes and try again.';
        } else if (errorMessage.contains('user-disabled')) {
          errorMessage =
              'This account has been disabled. Please contact support.';
        } else if (errorMessage.contains('network-request-failed')) {
          errorMessage =
              'No internet connection. Please check your network and try again.';
        } else if (errorMessage.contains('permission-denied')) {
          // Account was deleted from Firestore - don't sign out yet
          if (mounted) {
            setState(() {
              _showAccountDeleted = true;
              loading = false;
            });
          }
          return;
        } else {
          // Generic fallback for unknown errors
          errorMessage = 'Login failed. Please check your email and password.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show account deleted screen
    if (_showAccountDeleted) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                setState(() {
                  _showAccountDeleted = false;
                });
              }
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
                  await authService.logout();
                  if (mounted) {
                    setState(() {
                      _showAccountDeleted = false;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Leisurely Read',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Don\'t have an account? '),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
