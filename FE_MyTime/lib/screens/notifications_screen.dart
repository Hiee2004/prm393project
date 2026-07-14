import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/app_notification.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await MyTimeStore.instance.loadNotificationsFromApi();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (store.unreadNotificationCount > 0)
            TextButton(
              onPressed: () async {
                await store.markAllNotificationsAsRead();
              },
              child: const Text('Read all'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 42,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = store.notifications;
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No notifications yet.'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationTile(
                  item: item,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    if (!item.isRead) {
                      await store.markNotificationAsRead(item.id);
                    }

                    if (!mounted) return;

                    if (item.focusTaskId != null) {
                      final task = store.tasks.firstWhere(
                        (task) => int.tryParse(task.id) == item.focusTaskId,
                        orElse: () => store.tasks.isNotEmpty
                            ? store.tasks.first
                            : throw StateError('Task not found'),
                      );
                      store.selectTask(task);
                      navigator.pushNamed(AppRoutes.taskDetail);
                      return;
                    }

                    if (item.type == 'FocusCompleted' ||
                        item.type == 'DailyReview') {
                      navigator.pushNamed(AppRoutes.statistics);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: _IconBox(icon: _iconFor(item.type), isUnread: !item.isRead),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
          ),
        ),
        subtitle: Text(item.message),
        trailing: Text(_formatTime(item.sentAt ?? item.createdAt)),
        onTap: () async {
          await onTap();
        },
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.isUnread});

  final IconData icon;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surfaceSoft : AppColors.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'Reminder':
      return Icons.notifications_active_outlined;
    case 'FocusCompleted':
      return Icons.timer_outlined;
    case 'TaskOverdue':
      return Icons.warning_amber_rounded;
    case 'DailyReview':
      return Icons.bar_chart_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

String _formatTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
