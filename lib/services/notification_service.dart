import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  Future<List<AppNotification>> getMyNotifications() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (data as List).map((e) => AppNotification.fromMap(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);

    return (response as List).length;
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': false,
    });
  }
}
