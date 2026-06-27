import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return Scaffold(
      drawer: const _DashboardDrawer(),

      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        title: const Text('MyTime'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),

      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final task = store.selectedTask;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _HomeGreeting(),
              const SizedBox(height: 18),
              _TodayProgressCard(
                totalFocusTime: _formatMinutes(store.totalFocusSeconds),
                sessions: store.sessions.length,
                completedTasks: store.completedTaskCount,
                totalTasks: store.tasks.length,
              ),
              const SizedBox(height: 24),
              _UpcomingTasksSection(
                tasks: store.tasks.where((task) => !task.isCompleted).toList(),
                onViewAll: () => Navigator.pushNamed(context, AppRoutes.tasks),
                onOpen: (task) {
                  MyTimeStore.instance.selectTask(task);
                  Navigator.pushNamed(context, AppRoutes.taskDetail);
                },
              ),
              const SizedBox(height: 24),
              if (task != null) _CurrentFocusCard(task: task),
              if (task == null)
                _EmptyTaskCard(
                  onCreate: () =>
                      Navigator.pushNamed(context, AppRoutes.addTask),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(selectedIndex: 0),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.timer, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'MyTime',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DrawerMenuCard(
              children: [
                _DrawerTile(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  color: AppColors.primary,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerTile(
                  icon: Icons.checklist_outlined,
                  label: 'Tasks',
                  color: AppColors.primary,
                  onTap: () => _replaceWith(context, AppRoutes.tasks),
                ),
                _DrawerTile(
                  icon: Icons.add_task_outlined,
                  label: 'Create task',
                  color: AppColors.secondary,
                  onTap: () => _push(context, AppRoutes.addTask),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DrawerMenuCard(
              children: [
                _DrawerTile(
                  icon: Icons.timer_outlined,
                  label: 'Focus Time',
                  color: AppColors.primary,
                  onTap: () => _replaceWith(context, AppRoutes.focus),
                ),
                _DrawerTile(
                  icon: Icons.bar_chart_outlined,
                  label: 'Statistics',
                  color: AppColors.warning,
                  onTap: () => _replaceWith(context, AppRoutes.statistics),
                ),
                _DrawerTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                  color: AppColors.secondary,
                  onTap: () => _push(context, AppRoutes.calendar),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DrawerMenuCard(
              children: [
                _DrawerTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  color: AppColors.primary,
                  onTap: () => _push(context, AppRoutes.notifications),
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: AppColors.textSecondary,
                  onTap: () => _push(context, AppRoutes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _replaceWith(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, route);
  }

  void _push(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _DrawerMenuCard extends StatelessWidget {
  const _DrawerMenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 24,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hello, Student 🍁',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Let's make today productive!",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({
    required this.totalFocusTime,
    required this.sessions,
    required this.completedTasks,
    required this.totalTasks,
  });

  final String totalFocusTime;
  final int sessions;
  final int completedTasks;
  final int totalTasks;

  @override
  Widget build(BuildContext context) {
    final percent = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: CircularProgressIndicator(
                        value: percent.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceSoft,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percent * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Focused',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _ProgressMetric(
                      label: 'Focus Time',
                      value: totalFocusTime,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _ProgressMetric(
                      label: 'Tasks Done',
                      value: '$completedTasks/$totalTasks',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 12),
                    _ProgressMetric(
                      label: 'Sessions',
                      value: '$sessions',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _UpcomingTasksSection extends StatelessWidget {
  const _UpcomingTasksSection({
    required this.tasks,
    required this.onViewAll,
    required this.onOpen,
  });

  final List<FocusTask> tasks;
  final VoidCallback onViewAll;
  final ValueChanged<FocusTask> onOpen;

  @override
  Widget build(BuildContext context) {
    final upcoming = tasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Upcoming Tasks',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          AppCard(
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppColors.secondary),
                SizedBox(width: 10),
                Expanded(child: Text('No upcoming tasks. Enjoy the quiet.')),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final task in upcoming)
                  _UpcomingTaskTile(task: task, onTap: () => onOpen(task)),
              ],
            ),
          ),
      ],
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  const _UpcomingTaskTile({required this.task, required this.onTap});

  final FocusTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _priorityColor(task.priority),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${_formatDate(task.scheduledDate)} · ${task.focusMinutes} min',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.danger;
      case TaskPriority.medium:
        return AppColors.primary;
      case TaskPriority.low:
        return AppColors.secondary;
    }
  }
}

class _CurrentFocusCard extends StatelessWidget {
  const _CurrentFocusCard({required this.task});

  final FocusTask task;

  @override
  Widget build(BuildContext context) {
    final progress = task.outputs.isEmpty
        ? 0.0
        : task.completedOutputCount / task.outputs.length;
    final canStart = task.canStartToday;
    final outputs = task.outputs.take(3).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFCF4), Color(0xFFFFEBC2)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Selected focus',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    _MiniBadge(
                      icon: canStart
                          ? Icons.play_circle_outline
                          : Icons.event_available_outlined,
                      label: canStart ? 'Ready' : 'Plan',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskMetaChip(
                      icon: Icons.timer_outlined,
                      label: '${task.focusMinutes} min',
                    ),
                    _TaskMetaChip(
                      icon: Icons.check_circle_outline,
                      label:
                          '${task.completedOutputCount}/${task.outputs.length} output',
                    ),
                    _TaskMetaChip(
                      icon: Icons.event_outlined,
                      label: _formatDate(task.scheduledDate),
                    ),
                    _TaskMetaChip(
                      icon: Icons.repeat_rounded,
                      label: _repeatText(task.repeat),
                    ),
                    if (task.reminderEnabled)
                      _TaskMetaChip(
                        icon: Icons.notifications_active_outlined,
                        label: task.reminderTime,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Output progress',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    color: AppColors.primary,
                    backgroundColor: AppColors.progressTrack,
                  ),
                ),
                if (outputs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...outputs.map((output) => _OutputPreviewRow(output: output)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: task.isCompleted || !canStart
                        ? null
                        : () {
                            MyTimeStore.instance.startTask(task);
                            Navigator.pushNamed(context, AppRoutes.focus);
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      task.isCompleted
                          ? 'Completed'
                          : canStart
                          ? 'Start Focus Time'
                          : 'Available on ${_formatDate(task.scheduledDate)}',
                    ),
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMetaChip extends StatelessWidget {
  const _TaskMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputPreviewRow extends StatelessWidget {
  const _OutputPreviewRow({required this.output});

  final FocusOutput output;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: output.isCompleted ? const Color(0xFFECFDF3) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: output.isCompleted
              ? AppColors.success.withValues(alpha: 0.22)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            output.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: output.isCompleted ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              output.title,
              style: TextStyle(
                color: output.isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  const _EmptyTaskCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const Text('There is no task available for focus.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Create task'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMinutes(int seconds) {
  if (seconds < 60) return '${seconds}s';
  return '${seconds ~/ 60}m';
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
