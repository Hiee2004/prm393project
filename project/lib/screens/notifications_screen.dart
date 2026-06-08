import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<_NotificationItem> notifications = const [
    _NotificationItem(
      title: 'Time to start focus',
      message: 'Your task "Hoàn thành UI Flutter" starts at 09:00.',
      time: '08:55',
      type: NotificationType.focusReminder,
      isUnread: true,
    ),
    _NotificationItem(
      title: 'Avoid distractions',
      message: 'You recorded 2 distractions today. Try to focus on one task.',
      time: '10:15',
      type: NotificationType.distraction,
      isUnread: true,
    ),
    _NotificationItem(
      title: 'Break time',
      message: 'You have focused for 25 minutes. Take a short break.',
      time: '10:30',
      type: NotificationType.breakTime,
      isUnread: false,
    ),
    _NotificationItem(
      title: 'End day summary',
      message: 'Review your completed tasks, focus time and outputs.',
      time: '21:00',
      type: NotificationType.summary,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _Header(),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ReminderSummaryCard(
                    unreadCount: notifications.where((n) => n.isUnread).length,
                    totalCount: notifications.length,
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];

                      return _NotificationCard(
                        item: item,
                        onTap: () {
                          if (item.type == NotificationType.summary) {
                            Navigator.pushNamed(context, '/statistics');
                          } else {
                            Navigator.pushNamed(context, '/task-detail');
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _NotificationBottomNavBar(),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF43E08B), Color(0xFF23C7DD), Color(0xFF8A7CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Focus reminders, distraction alerts and end day summary.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ReminderSummaryCard extends StatelessWidget {
  final int unreadCount;
  final int totalCount;

  const _ReminderSummaryCard({
    required this.unreadCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF43D982).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF43D982),
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unreadCount unread reminders',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF07112D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount notifications today',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF65708A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getNotificationColor(item.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: item.isUnread ? typeColor : const Color(0xFFE5EAF3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_getNotificationIcon(item.type), color: typeColor),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF07112D),
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF65708A),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (item.isUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Unread',
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBottomNavBar extends StatelessWidget {
  const _NotificationBottomNavBar();

  void _onTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tasks');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/focus');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/statistics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE2FFF0),
      onDestinationSelected: (index) {
        _onTap(context, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer_rounded),
          label: 'Focus',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Stats',
        ),
      ],
    );
  }
}

enum NotificationType { focusReminder, distraction, breakTime, summary }

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isUnread;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isUnread,
  });
}

IconData _getNotificationIcon(NotificationType type) {
  if (type == NotificationType.focusReminder) {
    return Icons.timer_outlined;
  }

  if (type == NotificationType.distraction) {
    return Icons.block_rounded;
  }

  if (type == NotificationType.breakTime) {
    return Icons.free_breakfast_outlined;
  }

  return Icons.insights_rounded;
}

Color _getNotificationColor(NotificationType type) {
  if (type == NotificationType.focusReminder) {
    return const Color(0xFF43D982);
  }

  if (type == NotificationType.distraction) {
    return const Color(0xFFFF6B6B);
  }

  if (type == NotificationType.breakTime) {
    return const Color(0xFFFFB020);
  }

  return const Color(0xFF8A7CF6);
}
