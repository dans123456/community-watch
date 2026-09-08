import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../models/report_comment.dart';

class ReportService {
  final _client = Supabase.instance.client;

  Future<List<Report>> getReports({String? search}) async {
    final base = _client.from('reports').select();
    final cleanSearch = search != null
        ? search.trim().replaceAll(RegExp(r'[,()]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()
        : '';
    final data = cleanSearch.isNotEmpty
        ? await base.or(
            'title.ilike.%$cleanSearch%,location.ilike.%$cleanSearch%',
          ).order('created_at', ascending: false)
        : await base.order('created_at', ascending: false);
    return (data as List).map((e) => Report.fromMap(e)).toList();
  }

  Future<List<Report>> getMyReports() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client.from('reports').select().eq('user_id', uid).order('created_at', ascending: false);
    return (data as List).map((e) => Report.fromMap(e)).toList();
  }

  Future<String?> uploadImage(File file) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'jpg';
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_${file.path.hashCode.abs()}.$safeExt';
    await _client.storage.from('report-images').upload(path, file);
    return _client.storage.from('report-images').getPublicUrl(path);
  }

  Future<List<String>> uploadImages(List<File> files) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadImage(file);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime incidentAt,
    String? imageUrl,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) async {
    final effectiveUrls = imageUrls != null && imageUrls.isNotEmpty
        ? imageUrls
        : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : <String>[]);
    final primaryImage = effectiveUrls.isNotEmpty ? effectiveUrls.first : null;

    await _client.from('reports').insert({
      'user_id': _client.auth.currentUser!.id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'incident_at': incidentAt.toIso8601String(),
      'status': 'Pending',
      'image_url': primaryImage,
      'image_urls': effectiveUrls,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  Future<void> updateReport(String id, Map<String, dynamic> values) async {
    await _client.from('reports').update(values).eq('id', id);
  }

  Future<void> deleteReport(String id) async {
    await _client.from('reports').delete().eq('id', id);
  }

  Future<List<ReportComment>> getComments(String reportId) async {
    final data = await _client
        .from('report_comments')
        .select()
        .eq('report_id', reportId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ReportComment.fromMap(e)).toList();
  }

  Future<void> addComment(String reportId, String comment) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final profile = await _client
        .from('profiles')
        .select('full_name, role')
        .eq('id', user.id)
        .maybeSingle();

    final name = profile?['full_name'] ?? user.email?.split('@').first ?? 'Resident';
    final isOfficial = profile?['role'] == 'admin';

    await _client.from('report_comments').insert({
      'report_id': reportId,
      'user_id': user.id,
      'user_name': name,
      'comment': comment.trim(),
      'is_official': isOfficial,
    });
  }
}