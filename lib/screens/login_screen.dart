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
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
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
