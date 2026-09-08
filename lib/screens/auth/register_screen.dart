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
  final confirmPassword = TextEditingController();
  final _shake = ShakeController();

  bool loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    password.addListener(() => setState(() {}));
    confirmPassword.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  int _calculateStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#\$%^&*()_\-+=\[\]{};:,.<>?/\\|~`]').hasMatch(pass)) score++;
    return score;
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  Future<void> register() async {
    if ([name.text, email.text, password.text, confirmPassword.text].any((x) => x.trim().isEmpty)) {
      _shake.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please fill out all registration fields.'),
        ),
      );
      return;
    }

    if (password.text.length < 6) {
      _shake.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Password must be at least 6 characters long.'),
        ),
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      _shake.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Passwords do not match. Please verify your password.'),
        ),
      );
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
    final passText = password.text;
    final confirmText = confirmPassword.text;
    final strength = _calculateStrength(passText);
    final passwordsMatch = confirmText.isNotEmpty && confirmText == passText;
    final passwordsMismatch = confirmText.isNotEmpty && confirmText != passText;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeSlideIn(
            child: Shake(
              controller: _shake,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: name,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                        ),
                      ),
                    ),
                    if (passText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: List.generate(4, (i) {
                                  return Expanded(
                                    child: Container(
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      color: i < strength ? _strengthColor(strength) : Colors.grey.shade300,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _strengthLabel(strength),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _strengthColor(strength),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Include 8+ characters, uppercase, numbers, and symbols for a stronger password.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (passwordsMatch)
                              const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            else if (passwordsMismatch)
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                            ),
                          ],
                        ),
                        errorText: passwordsMismatch ? 'Passwords do not match' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    MotionButton(label: 'Create account', loading: loading, onPressed: loading ? null : register),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
