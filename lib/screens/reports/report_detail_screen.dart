import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/motion.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;
  const ReportDetailScreen({super.key, required this.report});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showMotionConfirm(
      context,
      title: 'Delete report?',
      message: 'This will permanently remove "${report.title}" from your reports.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed) return;
    await ReportService().deleteReport(report.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          FadeSlideIn(
            index: 0,
            child: Text(
              report.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 1,
            child: Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(report.category)),
                StatusChip(label: report.status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(index: 2, child: Text(report.description, style: const TextStyle(height: 1.5))),
          const SizedBox(height: 18),
          FadeSlideIn(
            index: 3,
            child: MotionCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const MapMarkerPulse(size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.location, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Incident location', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (report.latitude != null && report.longitude != null) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(report.latitude!, report.longitude!),
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.communitywatch.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(report.latitude!, report.longitude!),
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFD32F2F),
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (report.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FadeSlideIn(
                index: 4,
                child: Hero(
                  tag: 'report-image-${report.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(report.imageUrl!, height: 220, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          if (report.status == 'Pending')
            FadeSlideIn(
              index: 5,
              child: MotionButton(
                label: 'Delete Report',
                icon: Icons.delete_outline,
                variant: MotionButtonVariant.tonal,
                color: const Color(0xFFC62828),
                onPressed: () => _delete(context),
              ),
            ),
        ],
      ),
    );
  }
}
