import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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

  Position? _userPosition;
  bool _nearMeOnly = false;

  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'All',
    'Theft',
    'Robbery',
    'Assault',
    'Vandalism',
    'Fire',
    'Suspicious Activity',
    'Other',
  ];

  final List<String> _statuses = [
    'All',
    'Pending',
    'Under Investigation',
    'Resolved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    load();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (_) {}
  }

  double? _distanceToReport(Report r) {
    if (_userPosition == null || r.latitude == null || r.longitude == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      r.latitude!,
      r.longitude!,
    );
  }

  String? _formatDistance(Report r) {
    final meters = _distanceToReport(r);
    if (meters == null) return null;
    if (meters < 1000) {
      return '${meters.round()}m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }
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

  List<Report> get _filteredReports {
    return reports.where((r) {
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      final matchesStatus = _selectedStatus == 'All' || r.status == _selectedStatus;
      if (!matchesCategory || !matchesStatus) return false;
      if (_nearMeOnly) {
        final dist = _distanceToReport(r);
        if (dist == null || dist > 5000) return false;
      }
      return true;
    }).toList();
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
    final filtered = _filteredReports;
    final geoReports = filtered.where((r) => r.latitude != null && r.longitude != null).toList();

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
      body: Column(
        children: [
          if (!widget.myReports)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
          _buildFilterBar(),
          Expanded(
            child: _showMap
                ? _buildMapView(geoReports)
                : _buildListView(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'Category: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                for (final cat in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                for (final st in _statuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(st),
                      selected: _selectedStatus == st,
                      selectedColor: st != 'All' ? statusColor(st).withValues(alpha: 0.2) : null,
                      onSelected: (_) => setState(() => _selectedStatus = st),
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _selectedStatus == st && st != 'All' ? statusColor(st) : null,
                        fontWeight: _selectedStatus == st ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'Radar: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                FilterChip(
                  avatar: Icon(
                    Icons.radar,
                    size: 15,
                    color: _nearMeOnly ? Colors.white : const Color(0xFF123B5D),
                  ),
                  label: Text(_userPosition != null ? 'Near Me (< 5 km)' : 'Near Me (Enable GPS)'),
                  selected: _nearMeOnly,
                  selectedColor: const Color(0xFF123B5D),
                  checkmarkColor: Colors.white,
                  onSelected: (val) {
                    if (val && _userPosition == null) {
                      _getUserLocation();
                    }
                    setState(() => _nearMeOnly = val);
                  },
                  visualDensity: VisualDensity.compact,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: _nearMeOnly ? FontWeight.bold : FontWeight.normal,
                    color: _nearMeOnly ? Colors.white : Colors.black87,
                  ),
                ),
                if (_userPosition != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '📍 GPS active',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Report> list) {
    return loading
        ? ListView(
            padding: const EdgeInsets.all(12),
            children: List.generate(6, (_) => const ReportCardSkeleton()),
          )
        : list.isEmpty
            ? _EmptyState(myReports: widget.myReports)
            : RefreshIndicator(
                onRefresh: load,
                color: Theme.of(context).colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final distStr = _formatDistance(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FadeSlideIn(
                        index: i,
                        child: MotionCard(
                          onTap: () async {
                            final res = await pushAnimated(
                              context,
                              ReportDetailScreen(report: r),
                            );
                            if (res == true || mounted) load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: statusColor(r.status).withValues(alpha: 0.12),
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
                                      if (distStr != null || r.imageUrls.length > 1) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (distStr != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.near_me, size: 11, color: Colors.blueAccent),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      distStr,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.blueAccent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (r.imageUrls.length > 1) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.photo_library_outlined, size: 11, color: Colors.black54),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '${r.imageUrls.length}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
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
              );
  }

  Widget _buildMapView(List<Report> geoReports) {
    final LatLng centerPoint = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : (geoReports.isNotEmpty
            ? LatLng(geoReports.first.latitude!, geoReports.first.longitude!)
            : const LatLng(5.6037, -0.1870));

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: geoReports.isNotEmpty || _userPosition != null ? 13.5 : 3.0,
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
              markers: [
                if (_userPosition != null)
                  Marker(
                    point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    width: 46,
                    height: 46,
                    child: Tooltip(
                      message: 'You Are Here',
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...geoReports.map((r) {
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
                              color: color.withValues(alpha: 0.5),
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
                }),
              ],
            ),
          ],
        ),

        // Floating "Center on My Location" FAB
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton.small(
            heroTag: 'recenter_radar_user',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF123B5D),
            tooltip: 'Recenter on My Location',
            onPressed: () async {
              if (_userPosition == null) {
                await _getUserLocation();
              }
              if (_userPosition != null) {
                _mapController.move(
                  LatLng(_userPosition!.latitude, _userPosition!.longitude),
                  15.0,
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),

        // If no reports match filter with coordinates
        if (geoReports.isEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No reports match current filters with GPS coordinates.',
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
                              color: statusColor(_selectedReport!.status).withValues(alpha: 0.12),
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
                            onPressed: () async {
                              final sel = _selectedReport!;
                              final res = await pushAnimated(
                                context,
                                ReportDetailScreen(report: sel),
                              );
                              if (mounted) {
                                if (res == true) setState(() => _selectedReport = null);
                                load();
                              }
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
