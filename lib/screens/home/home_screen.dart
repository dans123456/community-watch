import 'package:flutter/material.dart';
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
          const SizedBox(height: 20),
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
                  index: i + 1,
                  child: _ActionCard(data: actions[i]),
                ),
            ],
          ),
        ],
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
