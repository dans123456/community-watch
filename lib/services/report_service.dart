import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportService {
  final _client = Supabase.instance.client;

  Future<List<Report>> getReports({String? search}) async {
    final base = _client.from('reports').select();
    final data = search != null && search.trim().isNotEmpty
        ? await base.or(
            'title.ilike.%${search.trim()}%,location.ilike.%${search.trim()}%',
          ).order('created_at', ascending: false)
        : await base.order('created_at', ascending: false);
    return (data as List).map((e) => Report.fromMap(e)).toList();
  }

  Future<List<Report>> getMyReports() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client.from('reports').select().eq('user_id', uid).order('created_at', ascending: false);
    return (data as List).map((e) => Report.fromMap(e)).toList();
  }

  Future<String?> uploadImage(File file) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('report-images').upload(path, file);
    return _client.storage.from('report-images').getPublicUrl(path);
  }

  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime incidentAt,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _client.from('reports').insert({
      'user_id': _client.auth.currentUser!.id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'incident_at': incidentAt.toIso8601String(),
      'status': 'Pending',
      'image_url': imageUrl,
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
}