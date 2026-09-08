import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/motion.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool admin = false;

  @override
  void initState() {
    super.initState();
    AuthService().isAdmin().then((a) {
      if (mounted) setState(() => admin = a);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showMotionConfirm(
      context,
      title: 'Log out?',
      message: "You'll need to sign in again to submit or view your reports.",
      confirmLabel: 'Log out',
      danger: true,
    );
    if (!confirmed) return;
    await AuthService().signOut();
    if (context.mounted) pushAndClearAnimated(context, const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          FadeSlideIn(
            index: 0,
            child: MotionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          const Text('Signed-in account', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (admin) ...[
            const SizedBox(height: 14),
            FadeSlideIn(
              index: 1,
              child: MotionCard(
                onTap: () => pushAnimated(context, const AdminDashboard()),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_outlined),
                      SizedBox(width: 14),
                      Expanded(child: Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w600))),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FadeSlideIn(
            index: 2,
            child: MotionButton(
              label: 'Logout',
              icon: Icons.logout,
              variant: MotionButtonVariant.tonal,
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
