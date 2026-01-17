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
        final userData = await authService.getUserData(user.uid);
        final role = userData['role'];
        final isApproved = userData['isApproved'] ?? false;

        print(
          'User logged in: ${user.email}, Role: $role, Approved: $isApproved',
        );

        if (role == 'admin') {
          if (mounted) Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'writer' && !isApproved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Writer account pending admin approval. Please wait.',
                ),
              ),
            );
          }
        } else if (role == 'writer') {
          if (mounted) Navigator.pushReplacementNamed(context, '/writer');
        } else {
          if (mounted) Navigator.pushReplacementNamed(context, '/reader');
        }
      }
    } catch (e) {
      if (mounted) {
        print('Login Error: $e');
        String errorMessage = e.toString();

        // Parse Firebase errors
        if (errorMessage.contains('user-not-found')) {
          errorMessage = 'Account not found. Please sign up first.';
        } else if (errorMessage.contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (errorMessage.contains('invalid-email')) {
          errorMessage = 'Invalid email format.';
        } else if (errorMessage.contains('too-many-requests')) {
          errorMessage =
              'Too many failed login attempts. Please try again later.';
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
