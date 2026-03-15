import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';
import '../services/notification_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/globals.dart';

class NotificationListModal extends StatefulWidget {
  final ScrollController? scrollController;

  const NotificationListModal({super.key, this.scrollController});

  @override
  State<NotificationListModal> createState() => _NotificationListModalState();
}

class _NotificationListModalState extends State<NotificationListModal> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  bool _testingNotification = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final notifications = await NotificationStorageService.getNotifications();
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (!notification.isRead) {
      await NotificationStorageService.markAsRead(notification.id);
      await _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationStorageService.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    await NotificationStorageService.deleteNotification(notification.id);
    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    await NotificationStorageService.clearAll();
    await _loadNotifications();
  }

  /// Test notification - shows an immediate test notification
  Future<void> _testNotification() async {
    if (_testingNotification) return;

    setState(() => _testingNotification = true);

    try {
      // Ensure service is initialized
      await NotificationService.initialize();

      // Show test notification
      await NotificationService.showNotification(
        title: '🧪 Notificación de Prueba',
        body:
            'Esta es una notificación de prueba. Si ves esto, las notificaciones funcionan correctamente.',
        id: 999999,
      );

      // Reload notifications to show the test one
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notificación de prueba enviada'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al mostrar notificación: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testingNotification = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Ahora';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('d MMM yyyy', 'es_AR').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Test notification button
                    IconButton(
                      icon: _testingNotification
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active),
                      tooltip: 'Probar notificación',
                      color: AppColors.primary,
                      onPressed: _testingNotification
                          ? null
                          : _testNotification,
                    ),
                    if (_notifications.any((n) => !n.isRead))
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Marcar todas'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    if (_notifications.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar todas',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar todas'),
                              content: const Text(
                                '¿Estás seguro de que deseas eliminar todas las notificaciones?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearAll();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay notificaciones',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(0),
        ),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : AppColors.primary.withOpacity(0.05),
            border: Border(
              left: BorderSide(
                color: notification.isRead
                    ? Colors.transparent
                    : AppColors.primary,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.transparent
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(notification.receivedAt),
                      style: TextStyle(fontSize: 11, color: AppColors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.black54,
                onPressed: () => _deleteNotification(notification),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
