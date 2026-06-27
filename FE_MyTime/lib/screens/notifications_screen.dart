import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_card.dart';

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
      icon: Icons.warning_amber_rounded,
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
      body: AnimatedBuilder(
        animation: MyTimeStore.instance,
        builder: (context, child) {
          final reminderTasks = MyTimeStore.instance.tasks
              .where((task) => task.reminderEnabled)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (reminderTasks.isNotEmpty) ...[
                Text(
                  'Task reminders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...reminderTasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReminderTaskTile(task: task),
                  );
                }),
                const SizedBox(height: 8),
              ],
              Text('General', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              ..._items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationTile(item: item),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderTaskTile extends StatelessWidget {
  const _ReminderTaskTile({required this.task});

  final FocusTask task;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: _IconBox(icon: Icons.notifications_active_outlined),
        title: Text(task.title),
        subtitle: Text(
          '${_formatDate(task.scheduledDate)} at ${task.reminderTime}'
          ' | ${_repeatText(task.repeat)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          MyTimeStore.instance.selectTask(task);
          Navigator.pushNamed(context, AppRoutes.taskDetail);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: _IconBox(icon: item.icon, isUnread: item.isUnread),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isUnread ? FontWeight.w800 : FontWeight.w600,
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
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.isUnread = true});

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

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

String _repeatText(TaskRepeat repeat) {
  switch (repeat) {
    case TaskRepeat.none:
      return 'No repeat';
    case TaskRepeat.daily:
      return 'Daily';
    case TaskRepeat.weekly:
      return 'Weekly';
    case TaskRepeat.monthly:
      return 'Monthly';
  }
}
