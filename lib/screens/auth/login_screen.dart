import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/motion.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final _shake = ShakeController();
  bool loading = false;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _shake.shake();
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().signIn(email.text.trim(), password.text);
      if (mounted) pushAndClearAnimated(context, const HomeScreen());
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: FadeSlideIn(
                child: Shake(
                  controller: _shake,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.shield_outlined, size: 70, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Community Watch',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Report, monitor and stay informed about your community.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: MotionButton(
                          label: 'Forgot password?',
                          variant: MotionButtonVariant.text,
                          expand: false,
                          onPressed: () => pushAnimated(context, const ForgotPasswordScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MotionButton(label: 'Login', loading: loading, onPressed: loading ? null : login),
                      const SizedBox(height: 12),
                      MotionButton(
                        label: 'Create account',
                        variant: MotionButtonVariant.outlined,
                        onPressed: () => pushAnimated(context, const RegisterScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
