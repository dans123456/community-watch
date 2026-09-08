import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/report.dart';
import '../../models/report_comment.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/pdf_export_service.dart';
import '../../widgets/motion.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _commentController = TextEditingController();
  final _reportService = ReportService();
  List<ReportComment> _comments = [];
  bool _loadingComments = true;
  bool _submittingComment = false;
  bool _isAdmin = false;
  bool _exportingPdf = false;
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadComments();
    AuthService().isAdmin().then((a) {
      if (mounted) setState(() => _isAdmin = a);
    });
  }

  Future<void> _loadComments() async {
    try {
      final list = await _reportService.getComments(widget.report.id);
      if (mounted) {
        setState(() {
          _comments = list;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submittingComment = true);
    try {
      await _reportService.addComment(widget.report.id, text);
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showMotionConfirm(
      context,
      title: 'Delete report?',
      message: 'This will permanently remove "${widget.report.title}" from your reports.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed) return;
    await _reportService.deleteReport(widget.report.id);
    if (context.mounted) Navigator.pop(context, true);
  }

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      await PdfExportService.exportReportDossier(
        widget.report,
        comments: _comments,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to export PDF dossier: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _openImageLightbox(BuildContext context, List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        final pageController = PageController(initialPage: initialIndex);
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.black.withValues(alpha: 0.95),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  urls.length > 1 ? '${currentIndex + 1} of ${urls.length}' : 'Evidence Photo',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                centerTitle: true,
              ),
              body: PageView.builder(
                controller: pageController,
                itemCount: urls.length,
                onPageChanged: (i) => setDialogState(() => currentIndex = i),
                itemBuilder: (context, i) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.network(
                        urls[i],
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            icon: _exportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Dossier (PDF)',
            onPressed: _exportingPdf ? null : _exportPdf,
          ),
        ],
      ),
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
          FadeSlideIn(
            index: 2,
            child: Text(report.description, style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            index: 3,
            child: MotionCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 22, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Incident: ${DateFormat('EEE, MMM d, yyyy • h:mm a').format(report.incidentAt.toLocal())}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reported: ${DateFormat('MMM d, yyyy • h:mm a').format(report.createdAt.toLocal())}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const MapMarkerPulse(size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report.location, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Incident location', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
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
          if (report.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FadeSlideIn(
                index: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Photo Evidence (${report.imageUrls.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Tap photo to zoom',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (report.imageUrls.length == 1)
                      GestureDetector(
                        onTap: () => _openImageLightbox(context, report.imageUrls, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              Image.network(
                                report.imageUrls.first,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Expand', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 230,
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    itemCount: report.imageUrls.length,
                                    onPageChanged: (i) => setState(() => _activeImageIndex = i),
                                    itemBuilder: (context, idx) {
                                      final url = report.imageUrls[idx];
                                      return GestureDetector(
                                        onTap: () => _openImageLightbox(context, report.imageUrls, idx),
                                        child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '${_activeImageIndex + 1} / ${report.imageUrls.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(report.imageUrls.length, (i) {
                              final isActive = _activeImageIndex == i;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF123B5D) : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

          // Incident Dossier Export Card
          const SizedBox(height: 6),
          FadeSlideIn(
            index: 5,
            child: MotionCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123B5D).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Color(0xFF123B5D), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Official Incident Dossier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Export formal case report with GPS & photos for police or insurance.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF123B5D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _exportingPdf ? null : _exportPdf,
                      child: _exportingPdf
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Updates & Discussion Section
          Text(
            'Updates & Discussion (${_comments.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Add Comment Input Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add an update or comment...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              _submittingComment
                  ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton.filled(
                      icon: const Icon(Icons.send, size: 20),
                      onPressed: _sendComment,
                    ),
            ],
          ),
          const SizedBox(height: 16),

          // Comments List
          if (_loadingComments)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_comments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No updates yet. Resident witnesses or responding authorities can post information above.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...List.generate(_comments.length, (i) {
              final c = _comments[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MotionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: c.isOfficial
                                  ? const Color(0xFF1565C0)
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: c.isOfficial ? Colors.white : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (c.isOfficial) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1565C0),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'OFFICIAL',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, h:mm a').format(c.createdAt.toLocal()),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(c.comment, style: const TextStyle(fontSize: 14, height: 1.3)),
                      ],
                    ),
                  ),
                ),
              );
            }),

          Builder(
            builder: (context) {
              final currentUid = Supabase.instance.client.auth.currentUser?.id;
              final canDelete = (report.userId == currentUid || _isAdmin);
              if (canDelete && (report.status == 'Pending' || _isAdmin)) {
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: 6,
                      child: MotionButton(
                        label: 'Delete Report',
                        icon: Icons.delete_outline,
                        variant: MotionButtonVariant.tonal,
                        color: const Color(0xFFC62828),
                        onPressed: () => _delete(context),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
