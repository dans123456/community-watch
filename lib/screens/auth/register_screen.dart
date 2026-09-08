import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/motion.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final _shake = ShakeController();
  bool loading = false;

  Future<void> register() async {
    if ([name.text, email.text, password.text].any((x) => x.trim().isEmpty)) {
      _shake.shake();
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().signUp(email.text.trim(), password.text, name.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Account created. Check your email if confirmation is enabled.'),
          ),
        );
        pushReplaceAnimated(context, const LoginScreen());
      }
    } catch (e) {
      _shake.shake();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeSlideIn(
            child: Shake(
              controller: _shake,
              child: Column(
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 14),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 24),
                  MotionButton(label: 'Create account', loading: loading, onPressed: loading ? null : register),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
