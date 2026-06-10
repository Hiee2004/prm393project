import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    _NotificationItem(
      title: 'Time to start focus',
      message: 'Your Flutter task starts at 09:00.',
      time: '08:55',
      icon: Icons.timer,
      isUnread: true,
    ),
    _NotificationItem(
      title: 'Avoid distractions',
      message: 'You recorded 2 distractions today.',
      time: '10:15',
      icon: Icons.warning,
      isUnread: true,
    ),
    _NotificationItem(
      title: 'Break time',
      message: 'You have focused for 25 minutes.',
      time: '10:30',
      icon: Icons.free_breakfast,
      isUnread: false,
    ),
    _NotificationItem(
      title: 'End day summary',
      message: 'Review your completed tasks and focus time.',
      time: '21:00',
      icon: Icons.bar_chart,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            leading: Icon(item.icon, color: Colors.blue),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: item.isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(item.message),
            trailing: Text(item.time),
            onTap: () {
              Navigator.pushNamed(
                context,
                item.icon == Icons.bar_chart
                    ? AppRoutes.statistics
                    : AppRoutes.taskDetail,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isUnread,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
}
