import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/motion.dart';
import '../reports/report_list_screen.dart';
import '../reports/create_report_screen.dart';
import '../admin/admin_dashboard.dart';
import '../profile/profile_screen.dart';

/// Shell that hosts the bottom-nav tabs. Each tab keeps its own Scaffold
/// (app bar included) so state is preserved across tab switches.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _admin = false;
  int _myPending = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await AuthService().isAdmin();
    final mine = await ReportService().getMyReports();
    if (mounted) {
      setState(() {
        _admin = a;
        _myPending = mine.where((r) => r.status == 'Pending').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(admin: _admin, onReturn: _load),
      const ReportListScreen(),
      const ReportListScreen(myReports: true),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Motion.normal,
        switchInCurve: Motion.curve,
        switchOutCurve: Motion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          children: [...previousChildren, if (currentChild != null) currentChild],
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: MotionBottomNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        items: [
          const NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          const NavItemData(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: 'Reports'),
          NavItemData(
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            label: 'My Reports',
            badgeCount: _myPending,
          ),
          const NavItemData(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final bool admin;
  final VoidCallback onReturn;
  const _DashboardTab({required this.admin, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[
      _ActionData(
        icon: Icons.add_alert,
        title: 'Report Incident',
        onTap: () => pushAnimated(context, const CreateReportScreen()).then((_) => onReturn()),
      ),
      _ActionData(
        icon: Icons.list_alt,
        title: 'Community Reports',
        onTap: () => pushAnimated(context, const ReportListScreen()),
      ),
      _ActionData(
        icon: Icons.history,
        title: 'My Reports',
        onTap: () => pushAnimated(context, const ReportListScreen(myReports: true)),
      ),
      if (admin)
        _ActionData(
          icon: Icons.dashboard_outlined,
          title: 'Admin Dashboard',
          onTap: () => pushAnimated(context, const AdminDashboard()),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Community Watch')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF123B5D), Color(0xFF2D6A8F)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay aware. Stay connected.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Help your community by reporting suspicious or unsafe incidents.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB71C1C).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'One-tap dial for police, fire & ambulance',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB71C1C),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: () => _showEmergencySheet(context),
                    child: const Text('Call Help', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (var i = 0; i < actions.length; i++)
                FadeSlideIn(
                  index: i + 2,
                  child: _ActionCard(data: actions[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency, color: Color(0xFFD32F2F), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Emergency Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap any service to instantly dial.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _EmergencyItem(
                icon: Icons.local_police_outlined,
                title: 'Police Emergency',
                number: '911',
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(height: 8),
              _EmergencyItem(
                icon: Icons.medical_services_outlined,
                title: 'Ambulance & Paramedics',
                number: '911',
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 8),
              _EmergencyItem(
                icon: Icons.local_fire_department_outlined,
                title: 'Fire & Rescue Service',
                number: '911',
                color: const Color(0xFFE65100),
              ),
              const SizedBox(height: 8),
              _EmergencyItem(
                icon: Icons.shield_outlined,
                title: 'Community Patrol Hotline',
                number: '112',
                color: const Color(0xFF6A1B9A),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String number;
  final Color color;

  const _EmergencyItem({
    required this.icon,
    required this.title,
    required this.number,
    required this.color,
  });

  Future<void> _dial() async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MotionCard(
      onTap: _dial,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(number, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text('Dial', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _ActionData({required this.icon, required this.title, required this.onTap});
}

class _ActionCard extends StatelessWidget {
  final _ActionData data;
  const _ActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return MotionCard(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
