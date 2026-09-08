import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/motion.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final service = ReportService();
  List<Report> reports = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      reports = await service.getReports();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int count(String s) => reports.where((r) => r.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: load,
        color: Theme.of(context).colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: loading
                  ? List.generate(4, (_) => const StatCardSkeleton())
                  : [
                      _Stat(index: 0, label: 'Total', value: reports.length, icon: Icons.report),
                      _Stat(index: 1, label: 'Pending', value: count('Pending'), icon: Icons.pending_actions),
                      _Stat(index: 2, label: 'Investigating', value: count('Under Investigation'), icon: Icons.search),
                      _Stat(index: 3, label: 'Resolved', value: count('Resolved'), icon: Icons.check_circle_outline),
                    ],
            ),
            const SizedBox(height: 24),
            Text('Recent Reports', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (loading)
              ...List.generate(4, (_) => const ReportCardSkeleton())
            else
              ...reports.take(20).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeSlideIn(
                    index: i,
                    child: MotionCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.category} • ${r.location}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            DropdownButton<String>(
                              value: r.status,
                              underline: const SizedBox.shrink(),
                              items: ['Pending', 'Under Investigation', 'Resolved', 'Rejected']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (s) async {
                                if (s == null) return;
                                await service.updateReport(r.id, {'status': s});
                                await load();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int index;
  final String label;
  final int value;
  final IconData icon;
  const _Stat({required this.index, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return FadeSlideIn(
      index: index,
      child: MotionCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value),
                    duration: Motion.slow,
                    curve: Motion.curve,
                    builder: (context, v, _) => Text(
                      '$v',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
