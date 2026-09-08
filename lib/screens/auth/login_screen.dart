import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
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
  final _biometricService = BiometricService();

  bool loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _initPreferencesAndBiometrics();
  }

  Future<void> _initPreferencesAndBiometrics() async {
    final remember = await _biometricService.getRememberMe();
    final savedEmail = await _biometricService.getSavedEmail();
    final canBio = await _biometricService.isBiometricsAvailable();

    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (savedEmail != null && savedEmail.isNotEmpty) {
          email.text = savedEmail;
        }
        _canUseBiometrics = canBio;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (!authenticated) return;

    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      if (mounted) pushAndClearAnimated(context, const HomeScreen());
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Biometrics verified. Please enter your password to sign in.'),
          ),
        );
      }
    }
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _shake.shake();
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().signIn(email.text.trim(), password.text);
      await _biometricService.saveRememberMe(
        email: email.text.trim(),
        remember: _rememberMe,
      );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                  maxWidth: 430,
                ),
                child: Center(
                  child: FadeSlideIn(
                    child: Shake(
                      controller: _shake,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.shield_outlined, size: 58, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 10),
                            Text(
                              'Community Watch',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Report, monitor and stay informed about your community.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email, AutofillHints.username],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: password,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
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
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                            activeColor: Theme.of(context).colorScheme.primary,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => pushAnimated(context, const ForgotPasswordScreen()),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MotionButton(label: 'Login', loading: loading, onPressed: loading ? null : login),
                            if (_canUseBiometrics) ...[
                              const SizedBox(height: 10),
                              MotionButton(
                                label: 'Sign in with Biometrics',
                                icon: Icons.fingerprint,
                                variant: MotionButtonVariant.tonal,
                                onPressed: _loginWithBiometrics,
                              ),
                            ],
                            const SizedBox(height: 10),
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
            );
          },
        ),
      ),
    );
  }
}
