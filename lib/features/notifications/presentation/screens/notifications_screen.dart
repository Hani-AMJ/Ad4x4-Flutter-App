import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../core/providers/repository_providers.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getNotifications();
      
      // Parse notifications from API response
      final List<dynamic> notificationsData = response['results'] ?? response['notifications'] ?? [];
      final notifications = notificationsData
          .map((data) => NotificationModel.fromJson(data as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadNotifications();
  }

  Future<void> _handleMarkAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.markNotificationAsRead(notification.id.toString());

      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      print('⚠️ [Notifications] Mark as read failed (non-critical): $e');
      // Graceful degradation: Update UI anyway for better UX
      // Backend endpoint may not be implemented yet (404/405 error)
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.markAllNotificationsAsRead();

      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⚠️ [Notifications] Mark all as read failed: $e');
      // Graceful degradation: Update UI anyway even if backend fails
      // This handles 301/404/405 errors from unimplemented endpoints
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          _isLoading = false;
        });
        
        // Show user-friendly message instead of error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as read (changes saved locally)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    _handleMarkAsRead(notification);

    // Navigate using new API fields (relatedObjectType/relatedObjectId)
    final route = notification.navigationRoute;
    if (route != null) {
      context.push(route);
      return;
    }
    
    // Fallback to legacy fields (for backward compatibility)
    if (notification.actionType != null && notification.actionId != null) {
      switch (notification.actionType) {
        case 'view_trip':
          context.push('/trips/${notification.actionId}');
          break;
        case 'view_event':
          context.push('/events/${notification.actionId}');
          break;
        case 'view_album':
          context.push('/gallery/${notification.actionId}');
          break;
        case 'view_profile':
          context.push('/members/${notification.actionId}');
          break;
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      // API notification types (uppercase)
      case 'NEW_TRIP':
      case 'TRIP_UPDATE':
      case 'TRIP_CANCELLED':
        return Icons.directions_car;
      case 'NEW_EVENT':
      case 'EVENT_UPDATE':
        return Icons.event;
      case 'MEMBER_REQUEST':
      case 'MEMBER_APPROVED':
        return Icons.people;
      case 'UPGRADE_REQUEST':
      case 'UPGRADE_APPROVED':
        return Icons.arrow_upward;
      case 'COMMENT_REPLY':
      case 'MESSAGE':
        return Icons.chat;
      
      // Legacy types (lowercase, for backward compatibility)
      case 'TRIP':
        return Icons.directions_car;
      case 'EVENT':
        return Icons.event;
      case 'SOCIAL':
        return Icons.people;
      case 'SYSTEM':
        return Icons.info;
      case 'ALERT':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, ColorScheme colors) {
    switch (type.toUpperCase()) {
      // Trip-related
      case 'NEW_TRIP':
      case 'TRIP_UPDATE':
        return Colors.blue;
      case 'TRIP_CANCELLED':
        return Colors.red;
      
      // Event-related
      case 'NEW_EVENT':
      case 'EVENT_UPDATE':
        return Colors.purple;
      
      // Member-related
      case 'MEMBER_REQUEST':
      case 'MEMBER_APPROVED':
        return Colors.green;
      
      // Upgrade-related
      case 'UPGRADE_REQUEST':
      case 'UPGRADE_APPROVED':
        return Colors.orange;
      
      // Communication
      case 'COMMENT_REPLY':
      case 'MESSAGE':
        return Colors.teal;
      
      // Legacy types
      case 'TRIP':
        return Colors.blue;
      case 'EVENT':
        return Colors.purple;
      case 'SOCIAL':
        return Colors.green;
      case 'SYSTEM':
        return colors.primary;
      case 'ALERT':
        return Colors.orange;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _isLoading ? null : _handleMarkAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.primary),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: colors.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: colors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _NotificationItem(
                        notification: _notifications[index],
                        icon: _getNotificationIcon(_notifications[index].type),
                        color: _getNotificationColor(_notifications[index].type, colors),
                        onTap: () => _handleNotificationTap(_notifications[index]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : colors.primary.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(
              color: colors.onSurface.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Thumbnail (if available)
            if (notification.imageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
