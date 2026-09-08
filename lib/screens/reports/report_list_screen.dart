import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/motion.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  final bool myReports;
  const ReportListScreen({super.key, this.myReports = false});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final service = ReportService();
  final search = TextEditingController();
  List<Report> reports = [];
  bool loading = true;
  bool _showMap = false;
  Report? _selectedReport;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      reports = widget.myReports
          ? await service.getMyReports()
          : await service.getReports(search: search.text);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Theft':
        return Icons.shopping_bag_outlined;
      case 'Robbery':
        return Icons.warning_amber_rounded;
      case 'Assault':
        return Icons.personal_injury_outlined;
      case 'Vandalism':
        return Icons.broken_image_outlined;
      case 'Fire':
        return Icons.local_fire_department_outlined;
      case 'Suspicious Activity':
        return Icons.visibility_outlined;
      default:
        return Icons.report_gmailerrorred_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final geoReports = reports.where((r) => r.latitude != null && r.longitude != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.myReports ? 'My Reports' : 'Community Reports'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.format_list_bulleted_rounded : Icons.map_outlined),
            tooltip: _showMap ? 'Show List View' : 'Show Map View',
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
                _selectedReport = null;
              });
            },
          ),
        ],
      ),
      body: _showMap
          ? _buildMapView(geoReports)
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        if (!widget.myReports)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onSubmitted: (_) => load(),
              decoration: InputDecoration(
                hintText: 'Search title or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: MotionIconButton(
                  icon: Icons.search,
                  onPressed: load,
                  tooltip: 'Search',
                ),
              ),
            ),
          ),
        Expanded(
          child: loading
              ? ListView(
                  padding: const EdgeInsets.all(12),
                  children: List.generate(6, (_) => const ReportCardSkeleton()),
                )
              : reports.isEmpty
                  ? _EmptyState(myReports: widget.myReports)
                  : RefreshIndicator(
                      onRefresh: load,
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reports.length,
                        itemBuilder: (context, i) {
                          final r = reports[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FadeSlideIn(
                              index: i,
                              child: MotionCard(
                                onTap: () => pushAnimated(
                                  context,
                                  ReportDetailScreen(report: r),
                                ).then((_) => load()),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: statusColor(r.status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(13),
                                        ),
                                        child: Icon(
                                          _categoryIcon(r.category),
                                          color: statusColor(r.status),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (r.latitude != null && r.longitude != null)
                                                  const Padding(
                                                    padding: EdgeInsets.only(right: 4),
                                                    child: Icon(Icons.pin_drop, size: 13, color: Colors.blueAccent),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    '${r.category} • ${r.location}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusChip(label: r.status),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMapView(List<Report> geoReports) {
    final LatLng centerPoint = geoReports.isNotEmpty
        ? LatLng(geoReports.first.latitude!, geoReports.first.longitude!)
        : const LatLng(5.6037, -0.1870);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: geoReports.isNotEmpty ? 13.5 : 3.0,
            onTap: (_, __) {
              if (_selectedReport != null) {
                setState(() => _selectedReport = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.communitywatch.app',
            ),
            MarkerLayer(
              markers: geoReports.map((r) {
                final isSelected = _selectedReport?.id == r.id;
                final color = statusColor(r.status);
                return Marker(
                  point: LatLng(r.latitude!, r.longitude!),
                  width: isSelected ? 52 : 42,
                  height: isSelected ? 52 : 42,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedReport = r);
                      _mapController.move(LatLng(r.latitude!, r.longitude!), 15.0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: isSelected ? 12 : 6,
                            spreadRadius: isSelected ? 3 : 1,
                          ),
                        ],
                        border: Border.all(color: color, width: isSelected ? 3.5 : 2),
                      ),
                      child: Icon(
                        _categoryIcon(r.category),
                        size: isSelected ? 26 : 20,
                        color: color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // If no reports have coordinates yet, show helpful overlay badge
        if (geoReports.isEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No reports with GPS coordinates yet. File a new report with GPS to see it on the map!',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Selected incident bottom card
        if (_selectedReport != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: FadeSlideIn(
              child: MotionCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor(_selectedReport!.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _categoryIcon(_selectedReport!.category),
                              color: statusColor(_selectedReport!.status),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedReport!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedReport!.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _selectedReport = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusChip(label: _selectedReport!.status),
                          TextButton.icon(
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('View Details'),
                            onPressed: () {
                              pushAnimated(
                                context,
                                ReportDetailScreen(report: _selectedReport!),
                              ).then((_) => load());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool myReports;
  const _EmptyState({required this.myReports});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                myReports ? "You haven't filed any reports yet." : 'No reports found.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
