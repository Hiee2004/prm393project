import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    unawaited(MyTimeStore.instance.loadTasksFromApi());
    unawaited(MyTimeStore.instance.loadSessionsFromApi());
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

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
          final todayTasks = _todayTasks(store.tasksForDate(_now));
          final task = _todaySelectedTask(store, todayTasks);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 116),
            children: [
              _HomeGreeting(now: _now, todayTaskCount: todayTasks.length),
              const SizedBox(height: 18),
              _TodayProgressCard(
                totalFocusTime: _formatMinutes(store.totalBackendFocusSeconds),
                sessions: store.focusSessions.length,
                completedTasks: store.completedTaskCount,
                totalTasks: todayTasks.length,
              ),
              const SizedBox(height: 24),
              _UpcomingTasksSection(
                tasks: todayTasks,
                today: _now,
                onViewAll: () => Navigator.pushNamed(context, AppRoutes.tasks),
                onOpen: (task) {
                  MyTimeStore.instance.selectTask(task);
                  Navigator.pushNamed(context, AppRoutes.taskDetail);
                },
                onToggleCompleted: (task) {
                  MyTimeStore.instance.setTaskCompleted(
                    task,
                    !task.isCompletedOn(_now),
                    occurrenceDate: _now,
                  );
                },
              ),
              const SizedBox(height: 24),
              if (task != null) _CurrentFocusCard(task: task),
              if (task == null)
                _TodayEmptyCard(
                  now: _now,
                  onCreate: () =>
                      Navigator.pushNamed(context, AppRoutes.addTask),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
    );
  }

  List<FocusTask> _todayTasks(List<FocusTask> tasks) {
    final result = [...tasks];
    result.sort((first, second) {
      if (first.isCompleted != second.isCompleted) {
        return first.isCompleted ? 1 : -1;
      }
      return first.scheduledDate.compareTo(second.scheduledDate);
    });
    return result;
  }

  FocusTask? _todaySelectedTask(MyTimeStore store, List<FocusTask> todayTasks) {
    final selected = store.selectedTask;
      if (selected != null && todayTasks.any((task) => task.id == selected.id)) {
        return selected;
      }

    for (final task in todayTasks) {
      if (!task.isCompletedOn(_now)) return task;
    }

    return null;
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: theme.drawerTheme.backgroundColor,
      shape: theme.drawerTheme.shape,
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
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: scene.navGlow,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.timer, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MyTime',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
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
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerTile(
                  icon: Icons.checklist_outlined,
                  label: 'Tasks',
                  color: theme.colorScheme.primary,
                  onTap: () => _replaceWith(context, AppRoutes.tasks),
                ),
                _DrawerTile(
                  icon: Icons.add_task_outlined,
                  label: 'Create task',
                  color: theme.colorScheme.secondary,
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
                  color: theme.colorScheme.primary,
                  onTap: () => _replaceWith(context, AppRoutes.focus),
                ),
                _DrawerTile(
                  icon: Icons.bar_chart_outlined,
                  label: 'Statistics',
                  color: theme.colorScheme.primary.withValues(alpha: 0.76),
                  onTap: () => _replaceWith(context, AppRoutes.statistics),
                ),
                _DrawerTile(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Streak',
                  color: theme.colorScheme.secondary,
                  onTap: () => _push(context, AppRoutes.productivityStreak),
                ),
                _DrawerTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                  color: theme.colorScheme.secondary,
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
                  color: theme.colorScheme.primary,
                  onTap: () => _push(context, AppRoutes.notifications),
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
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
    final theme = Theme.of(context);

    return ListTile(
      minLeadingWidth: 24,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
      ),
      onTap: onTap,
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({required this.now, required this.todayTaskCount});

  final DateTime now;
  final int todayTaskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;
    final dateText = _formatDashboardDate(now);
    final timeText = _formatDashboardTime(now);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, Student', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                "Let's make today productive!",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$dateText | $timeText',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todayTaskCount == 0
                    ? 'No tasks planned for today yet.'
                    : '$todayTaskCount task(s) planned for today.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.72 : 0.92,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scene.cardBorder),
            boxShadow: [
              BoxShadow(
                color: scene.navGlow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(scene.accentIcon, color: theme.colorScheme.primary),
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
    final theme = Theme.of(context);
    final percent = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: theme.textTheme.titleMedium?.copyWith(
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
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.secondary.withValues(
                          alpha: 0.18,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percent * 100).round()}%',
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text('Focused', style: theme.textTheme.bodySmall),
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
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _ProgressMetric(
                      label: 'Tasks Done',
                      value: '$completedTasks/$totalTasks',
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    _ProgressMetric(
                      label: 'Sessions',
                      value: '$sessions',
                      color: theme.colorScheme.primary.withValues(alpha: 0.76),
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
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
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
    required this.today,
    required this.onViewAll,
    required this.onOpen,
    required this.onToggleCompleted,
  });

  final List<FocusTask> tasks;
  final DateTime today;
  final VoidCallback onViewAll;
  final ValueChanged<FocusTask> onOpen;
  final ValueChanged<FocusTask> onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleTasks = tasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Upcoming Tasks', style: theme.textTheme.titleLarge),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 10),
        if (visibleTasks.isEmpty)
          AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No task planned for ${_formatDate(today)}. Add one to get started.',
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final task in visibleTasks)
                  _UpcomingTaskTile(
                    task: task,
                    today: today,
                    onTap: () => onOpen(task),
                    onToggleCompleted: () => onToggleCompleted(task),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  const _UpcomingTaskTile({
    required this.task,
    required this.today,
    required this.onTap,
    required this.onToggleCompleted,
  });

  final FocusTask task;
  final DateTime today;
  final VoidCallback onTap;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompletedOn(today);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _priorityColor(theme, task.priority),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          decoration: isCompleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          color: isCompleted
              ? theme.colorScheme.onSurface.withValues(alpha: 0.52)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        '${task.focusMinutes} min${task.reminderEnabled ? ' | ${_formatReminderTime(task.reminderTime)}' : ''}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isCompleted
              ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
              : null,
        ),
      ),
      trailing: InkWell(
        onTap: onToggleCompleted,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: task.isCompleted
                ? theme.colorScheme.primary
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.55),
              width: 1.6,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: isCompleted ? Colors.white : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Color _priorityColor(ThemeData theme, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return theme.colorScheme.error;
      case TaskPriority.medium:
        return theme.colorScheme.primary;
      case TaskPriority.low:
        return theme.colorScheme.secondary;
    }
  }
}

class _CurrentFocusCard extends StatefulWidget {
  const _CurrentFocusCard({required this.task});

  final FocusTask task;

  @override
  State<_CurrentFocusCard> createState() => _CurrentFocusCardState();
}

class _CurrentFocusCardState extends State<_CurrentFocusCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;
    final task = widget.task;
    final progress = task.outputs.isEmpty
        ? 0.0
        : task.completedOutputCount / task.outputs.length;
    final canStart = task.canStartToday;
    final isCompleted = task.isCompletedOn(DateTime.now());
    final outputs = task.outputs.take(3).toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scene.navGlow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.focusMinutes} min • ${task.completedOutputCount}/${task.outputs.length} outputs',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _expanded ? 'Hide details' : 'Show details',
                onPressed: () {
                  setState(() => _expanded = !_expanded);
                },
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniBadge(
                icon: canStart
                    ? Icons.play_circle_outline
                    : Icons.event_available_outlined,
                label: canStart ? 'Ready' : 'Plan',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.secondary.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 14),
            Text(task.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
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
            if (outputs.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...outputs.map((output) => _OutputPreviewRow(output: output)),
            ],
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCompleted || !canStart
                  ? null
                  : () {
                      MyTimeStore.instance.startTask(task);
                      Navigator.pushNamed(context, AppRoutes.focus);
                    },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                isCompleted
                    ? 'Completed'
                    : canStart
                    ? 'Focus on this task'
                    : 'Available on ${_formatDate(task.scheduledDate)}',
              ),
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
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.70 : 0.92,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scene.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.58 : 0.78,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: output.isCompleted
            ? theme.colorScheme.secondary.withValues(alpha: 0.14)
            : theme.colorScheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.60 : 0.88,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: output.isCompleted
              ? theme.colorScheme.secondary.withValues(alpha: 0.34)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            output.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: output.isCompleted
                ? theme.colorScheme.secondary
                : theme.colorScheme.onSurface.withValues(alpha: 0.42),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              output.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: output.isCompleted
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.74)
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayEmptyCard extends StatelessWidget {
  const _TodayEmptyCard({required this.now, required this.onCreate});

  final DateTime now;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No active task for ${_formatDate(now)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Today is still empty. Create a task for this date and it will appear here automatically.',
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create today task'),
          ),
        ],
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

String _formatDashboardDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatDashboardTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatReminderTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;

  final isPm = hour >= 12;
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final suffix = isPm ? 'PM' : 'AM';
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
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
