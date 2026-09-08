import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/motion.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final _shake = ShakeController();
  bool loading = false;

  Future<void> send() async {
    if (email.text.trim().isEmpty) {
      _shake.shake();
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().resetPassword(email.text.trim());
      if (mounted) {
        await showSuccessOverlay(context, message: 'Password reset email sent.');
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
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeSlideIn(
          child: Shake(
            controller: _shake,
            child: Column(
              children: [
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 20),
                MotionButton(label: 'Send reset link', loading: loading, onPressed: loading ? null : send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
