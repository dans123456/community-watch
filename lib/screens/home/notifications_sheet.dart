import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class NotificationsSheet extends StatefulWidget {
  final VoidCallback? onNotificationsChanged;

  const NotificationsSheet({super.key, this.onNotificationsChanged});

  static Future<void> show(BuildContext context, {VoidCallback? onNotificationsChanged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(onNotificationsChanged: onNotificationsChanged),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final _service = NotificationService();
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAsRead(AppNotification notif) async {
    if (notif.isRead) return;
    try {
      await _service.markAsRead(notif.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notif.id);
          if (idx != -1) {
            _notifications[idx] = notif.copyWith(isRead: true);
          }
        });
        widget.onNotificationsChanged?.call();
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        widget.onNotificationsChanged?.call();
      }
    } catch (_) {}
  }

  Future<void> _delete(AppNotification notif) async {
    try {
      await _service.deleteNotification(notif.id);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notif.id);
        });
        widget.onNotificationsChanged?.call();
      }
    } catch (_) {}
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: Color(0xFF123B5D)),
                    const SizedBox(width: 10),
                    Text(
                      'Notifications',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: _markAllRead,
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Mark all read', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 64,
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications yet',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "You'll get updates here when administrators review or resolve incidents you've reported.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _notifications.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                final isStatusResolved = notif.message.toLowerCase().contains('resolved');
                                final isStatusRejected = notif.message.toLowerCase().contains('rejected');
                                final isStatusInvestigating = notif.message.toLowerCase().contains('investigation');

                                IconData iconData = Icons.notifications_rounded;
                                Color iconColor = const Color(0xFF123B5D);

                                if (isStatusResolved) {
                                  iconData = Icons.check_circle_outline_rounded;
                                  iconColor = Colors.green;
                                } else if (isStatusRejected) {
                                  iconData = Icons.cancel_outlined;
                                  iconColor = Colors.redAccent;
                                } else if (isStatusInvestigating) {
                                  iconData = Icons.search_rounded;
                                  iconColor = Colors.orange;
                                }

                                return Dismissible(
                                  key: Key(notif.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    color: Colors.redAccent,
                                    child: const Icon(Icons.delete_outline, color: Colors.white),
                                  ),
                                  onDismissed: (_) => _delete(notif),
                                  child: ListTile(
                                    tileColor: notif.isRead
                                        ? Colors.transparent
                                        : theme.colorScheme.primary.withValues(alpha: 0.05),
                                    onTap: () => _markAsRead(notif),
                                    leading: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: iconColor.withValues(alpha: 0.12),
                                          foregroundColor: iconColor,
                                          child: Icon(iconData, size: 22),
                                        ),
                                        if (!notif.isRead)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: theme.scaffoldBackgroundColor,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          notif.message,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: notif.isRead ? Colors.grey[600] : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(notif.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                      onPressed: () => _delete(notif),
                                      tooltip: 'Delete notification',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
